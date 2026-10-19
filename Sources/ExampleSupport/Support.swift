import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Loams

/// Namespace every example reads and writes. Nothing else is touched.
public let exampleNamespace = "examples-swift"

public func makeClient() throws -> (client: Loams, endpoint: URL) {
    let env = ProcessInfo.processInfo.environment
    let endpoint = URL(string: env["LOAMS_ENDPOINT"] ?? "http://127.0.0.1:18080")!
    let key = env["LOAMS_API_KEY"] ?? ""
    let client = try Loams(
        Options(
            endpoint: endpoint,
            auth: key.isEmpty ? nil : APIKeyTokenSource(key),
            transport: TransportConfig(endpoint: endpoint, protocol_: .connect, codec: .json)
        )
    )
    return (client, endpoint)
}

/// A binding for an RPC the SDK facade has no module for yet. The call still goes
/// through the SDK's invoker: auth, retries, error mapping.
func binding(_ service: String, _ method: String, readOnly: Bool) -> CallBinding {
    let pkg = "loams.collection.v1"
    return CallBinding(
        module: "collections", name: method, protoName: method, method: method,
        rpc: "\(pkg).\(service)/\(method)", service: "\(pkg).\(service)", package: pkg,
        idempotency: readOnly ? .noSideEffects : .idempotent,
        retry: readOnly ? .safe : .manual,
        streaming: .unary,
        takesIdempotencyKey: method == "WriteDocuments"
    )
}

public struct Collections: Sendable {
    public let client: Loams
    public init(_ client: Loams) { self.client = client }

    func call(_ service: String, _ method: String, readOnly: Bool, _ fields: [String: JSONValue]) async throws -> [String: JSONValue] {
        let request = DynamicMessage(protoTypeName: "loams.collection.v1.\(method)Request", fields: fields)
        let response: DynamicMessage = try await client.invoker.unary(
            binding: binding(service, method, readOnly: readOnly), request: request)
        return response.fields
    }

    public func createNamespace(_ name: String) async throws {
        do {
            _ = try await call("NamespaceService", "CreateNamespace", readOnly: false, ["namespace": .string(name)])
        } catch let error as LoamsError {
            // Re-running an example finds the namespace already there.
            if case .loams(.alreadyExists, _, _, _, _, _, _) = error { return }
            throw error
        }
    }

    public func createCollection(_ name: String, schema: JSONValue) async throws {
        _ = try await call("CollectionService", "CreateCollection", readOnly: false, [
            "namespace": .string(exampleNamespace), "name": .string(name), "schema": schema,
        ])
    }

    /// Upserts `(id, source, embedding)` documents with string ids.
    public func upsert(_ collection: String, docs: [(id: String, source: [String: JSONValue], embedding: [Double])]) async throws {
        let ops: [JSONValue] = docs.map { d in
            .object(["upsert": .object([
                "id": .object(["string": .string(d.id)]),
                "source": .object(d.source),
                "vectors": .object(["embedding": .array(d.embedding.map { .number($0) })]),
            ])])
        }
        _ = try await call("DocumentService", "WriteDocuments", readOnly: false, [
            "namespace": .string(exampleNamespace), "collection": .string(collection), "ops": .array(ops),
        ])
    }

    /// Hybrid search: vector + BM25 text, fused with RRF, optionally filtered by `tenant`.
    public func hybridSearch(_ collection: String, text: String, vector: [Double], tenant: String? = nil, limit: Int = 3) async throws -> [Hit] {
        var fields: [String: JSONValue] = [
            "namespace": .string(exampleNamespace),
            "collection": .string(collection),
            "retrievers": .array([
                .object(["vector": .object(["field": .string("embedding"), "query": .array(vector.map { .number($0) }), "k": .int(10)])]),
                .object(["text": .object([
                    "query": .object(["match": .object(["field": .string("body"), "text": .string(text)])]),
                    "k": .int(10),
                ])]),
            ]),
            "fusion": .object(["rrf": .object(["k": .int(60)])]),
            "limit": .int(limit),
        ]
        if let tenant {
            fields["filter"] = .object(["term": .object(["field": .string("tenant"), "value": .string(tenant)])])
        }
        let response = try await call("QueryService", "Search", readOnly: true, fields)
        return (response["hits"]?.arrayValue ?? []).compactMap { value in
            guard let hit = value.objectValue else { return nil }
            let source = hit["source"]?.objectValue ?? [:]
            return Hit(
                id: hit["pk"]?.objectValue?["string"]?.stringValue ?? "?",
                score: hit["score"].flatMap(number) ?? 0,
                body: source["body"]?.stringValue ?? "",
                tenant: source["tenant"]?.stringValue ?? ""
            )
        }
    }
}

public struct Hit: Sendable {
    public let id: String
    public let score: Double
    public let body: String
    public let tenant: String
}

func number(_ value: JSONValue) -> Double? {
    if let i = value.intValue { return Double(i) }
    if case .number(let d) = value { return d }
    return nil
}

/// The kb schema: `body` (text), `tenant` (keyword), `embedding` (dim 3, cosine).
public let kbSchema: JSONValue = .object([
    "fields": .array([
        .object(["name": .string("body"), "source_path": .string("body"),
                 "kind": .object(["text": .object(["analyzer": .string("standard"), "positions": .bool(true)])]),
                 "indexed": .bool(true), "fast": .bool(false)]),
        .object(["name": .string("tenant"), "source_path": .string("tenant"),
                 "kind": .string("keyword"), "indexed": .bool(true), "fast": .bool(true)]),
    ]),
    "vectors": .array([.object(["name": .string("embedding"), "dim": .int(3), "distance": .string("cosine")])]),
    "sparse_vectors": .array([]),
    "dynamic": .string("ignore"),
    "max_fields": .int(1000),
])

public let kbDocs: [(id: String, source: [String: JSONValue], embedding: [Double])] = [
    ("1", ["body": .string("refund policy"), "tenant": .string("a")], [1.0, 0.0, 0.0]),
    ("2", ["body": .string("shipping times"), "tenant": .string("a")], [0.9, 0.1, 0.0]),
    ("3", ["body": .string("refund window"), "tenant": .string("b")], [0.0, 0.0, 1.0]),
]

/// Sets up the example namespace and `kb` collection with the sample documents.
public func seed(_ collections: Collections, collection: String = "kb") async throws {
    try await collections.createNamespace(exampleNamespace)
    try await collections.createCollection(collection, schema: kbSchema)
    try await collections.upsert(collection, docs: kbDocs)
}

/// Runs SQL over the namespace's collections. The SDK has no SQL module yet, so
/// this posts to the engine's REST route directly.
public func runSQL(endpoint: URL, query: String) async throws -> (columns: [String], rows: [[JSONValue]]) {
    var request = URLRequest(url: endpoint.appendingPathComponent("v1/namespaces/\(exampleNamespace)/sql"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    if let key = ProcessInfo.processInfo.environment["LOAMS_API_KEY"], !key.isEmpty {
        request.setValue("Bearer \(key)", forHTTPHeaderField: "authorization")
    }
    request.httpBody = try JSONValue.object(["query": .string(query), "consistency": .string("strong")]).encoded()
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let object = JSONValue.decodedObject(from: data) else { throw ExampleError.badResponse }
    if (response as? HTTPURLResponse)?.statusCode ?? 0 >= 300 {
        throw ExampleError.sql(object["message"]?.stringValue ?? "request failed")
    }
    let columns = (object["columns"]?.arrayValue ?? []).compactMap { $0.objectValue?["name"]?.stringValue }
    let rows = (object["rows"]?.arrayValue ?? []).map { $0.arrayValue ?? [] }
    return (columns, rows)
}

public enum ExampleError: Error { case badResponse, sql(String) }
