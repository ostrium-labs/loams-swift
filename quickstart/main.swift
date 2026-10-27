import ExampleSupport
import Foundation
import Loams

// Complete 0.1.2 module tour: instance/system, namespace, collection,
// documents, text/vector/hybrid search, optional graph, SDK SQL and streams.
let loams = try makeClient()
let info = try await loams.instance.getInstance()
print("connected to \(info.name) \(info.serverVersion)")
let version = try await loams.system.version()
let catalogue = try await loams.system.catalogue()
print("SDK/server compatible: \(version.compatible); served packages: \(catalogue.served.count)")

try await seed(loams, collection: "sdk_tour")
let notes = loams.collection("sdk_tour")
let got = try await notes.get([1, 3])
let count = try await notes.count(where: Filter.eq("tenant", "a"))
print("documents fetched: \(got.fields["documents"]?.arrayValue?.count ?? 0); tenant a count: \(count)")
for try await doc in notes.scrollAll(limit: 10) { _ = doc }
_ = try await notes.patch(2, set: ["body": .string("shipping times and carriers")])

let text = try await loams.search.query(
    Search.on("sdk_tour").text("refund", fields: ["body"]).filter(Filter.eq("tenant", "a"))
        .sort(.score(), .pk()).limit(5))
let vector = try await loams.vector.search("sdk_tour", vector: [1, 0, 0], field: "embedding", limit: 5)
let hybrid = try await loams.search.query(
    Search.on("sdk_tour").text("refund", fields: ["body"]).vector("embedding", [1, 0, 0])
        .fuse(.rrf(k: 60)).limit(5))
print("text/vector/hybrid hit counts: \(hits(text)), \(hits(vector)), \(hits(hybrid))")

let rows = try await loams.sql.query("SELECT tenant, count(*) AS n FROM sdk_tour GROUP BY tenant ORDER BY tenant")
print("SQL records: \(SqlModule.records(rows).count)")

_ = try await loams.streams.create("sdk-tour-events", partitions: 1)
let produced = try await loams.streams.produce("sdk-tour-events", records: [
    ProducerRecord(key: "seed", value: JSONValue.object(["kind": .string("example-seeded")]))
], producerId: "examples-swift-sdk-tour", producerSeq: 1)
let base = UInt64(produced.fields["baseOffset"]?.stringValue ?? "0") ?? 0
let last = UInt64(produced.fields["lastOffset"]?.stringValue ?? "0") ?? 0
for try await record in loams.streams.subscribe("sdk-tour-events", from: base) {
    print("stream event at \(record.offset)")
    if record.offset >= last { break }
}

if try await loams.system.availableModule("graph") {
    do { _ = try await loams.graph.create("examples_swift_sdk_tour") }
    catch let error as LoamsError where error.code == .alreadyExists { }
    let graph = try await loams.graph.query("examples_swift_sdk_tour", "RETURN 1 AS ready", readOnly: true)
    if case .object(let rowSet)? = graph.fields["rows"], case .array(let records)? = rowSet["rows"] {
        print("graph returned \(records.count) row(s)")
    }
} else {
    print("graph is not served by this instance")
}

func hits(_ response: DynamicMessage) -> Int { response.fields["hits"]?.arrayValue?.count ?? 0 }
