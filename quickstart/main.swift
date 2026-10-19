import ExampleSupport
import Loams

// Connect, create a collection, upsert documents, run a hybrid search.
let (client, _) = try makeClient()
let info = try await client.instance.getInstance()
print("instance: \(info.name) \(info.serverVersion)")

let collections = Collections(client)
try await seed(collections)
print("seeded \(exampleNamespace)/kb with \(kbDocs.count) documents")

// Vector near doc 1 + BM25 for "refund", fused with RRF, restricted to tenant a.
let hits = try await collections.hybridSearch("kb", text: "refund", vector: [1, 0, 0], tenant: "a")
for hit in hits {
    print("id=\(hit.id) score=\(hit.score) tenant=\(hit.tenant) body=\(hit.body)")
}
