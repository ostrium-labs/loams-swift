import ExampleSupport
import Foundation

// docsearch: a small search CLI over the sample knowledge base.
//
//   swift run docsearch "refund" [--tenant a] [--limit 2]
//
// The query text is matched with BM25; the embedding is a toy 3-d vector derived
// from the text so the example needs no model: "refund" leans toward the first
// axis, "shipping" toward the second, anything else toward the third.
func take(_ name: String, from args: inout [String]) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    let value = args[i + 1]
    args.removeSubrange(i...(i + 1))
    return value
}
var args = Array(CommandLine.arguments.dropFirst())
let tenant = take("--tenant", from: &args)
let limit = Int(take("--limit", from: &args) ?? "") ?? 3
let query = args.joined(separator: " ")
guard !query.isEmpty else {
    print("usage: docsearch <query> [--tenant a|b] [--limit n]")
    exit(2)
}

func embed(_ text: String) -> [Double] {
    let t = text.lowercased()
    if t.contains("refund") { return [1, 0, 0] }
    if t.contains("shipping") { return [0, 1, 0] }
    return [0, 0, 1]
}

let (client, _) = try makeClient()
let collections = Collections(client)
try await seed(collections)  // idempotent: re-running upserts the same documents
let hits = try await collections.hybridSearch("kb", text: query, vector: embed(query), tenant: tenant, limit: limit)
if hits.isEmpty { print("no results") }
for (rank, hit) in hits.enumerated() {
    print("\(rank + 1). [\(hit.tenant)] \(hit.body)  (score \(String(format: "%.4f", hit.score)))")
}
