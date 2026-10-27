import Foundation
import Loams

/// Every Swift example reads and writes only this namespace.
public let exampleNamespace = "examples-swift"

public func makeClient() throws -> Loams {
    var options = try Options.fromEnvironment()
    options.namespace = exampleNamespace
    options.sessionConsistency = true
    return try Loams(options)
}

/// Seeds one small searchable collection through the public SDK modules. Repeated
/// runs upsert the same IDs; the helper never drops a collection or namespace.
public func seed(_ loams: Loams, collection: String = "kb") async throws {
    do { _ = try await loams.namespaces.create(exampleNamespace) }
    catch let error as LoamsError where error.code == .alreadyExists { }

    let schema = Schema().text("body").keyword("tenant").vector("embedding", dim: 3)
    do { _ = try await loams.collections.create(collection, schema: schema) }
    catch let error as LoamsError where error.code == .alreadyExists { }

    let docs = [
        Doc(1, ["body": .string("refund policy"), "tenant": .string("a")], vectors: ["embedding": [1, 0, 0]]),
        Doc(2, ["body": .string("shipping times"), "tenant": .string("a")], vectors: ["embedding": [0, 1, 0]]),
        Doc(3, ["body": .string("refund window"), "tenant": .string("b")], vectors: ["embedding": [0, 0, 1]]),
    ]
    _ = try await loams.documents.upsert(collection, docs)
}
