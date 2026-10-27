import ExampleSupport
import Foundation
import Loams

// docsearch: high-level SDK hybrid search over the sample knowledge base.
//
//   swift run docsearch "refund" [--tenant a] [--limit 2]
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
    let value = text.lowercased()
    if value.contains("refund") { return [1, 0, 0] }
    if value.contains("shipping") { return [0, 1, 0] }
    return [0, 0, 1]
}

let loams = try makeClient()
try await seed(loams)
var request = Search.on("kb").text(query, fields: ["body"])
    .vector("embedding", embed(query)).fuse(.rrf(k: 60)).limit(limit)
if let tenant { request = request.filter(Filter.eq("tenant", tenant)) }
let response = try await loams.search.query(request)
guard case .array(let found)? = response.fields["hits"] else {
    print("no results")
    exit(0)
}
if found.isEmpty { print("no results") }
for (rank, hit) in found.enumerated() {
    guard case .object(let fields) = hit else { continue }
    let id = DocumentID(json: fields["pk"])?.text ?? "?"
    let score = number(fields["score"]) ?? 0
    let source = fields["source"]?.objectValue ?? [:]
    let body = source["body"]?.stringValue ?? ""
    let value = source["tenant"]?.stringValue ?? ""
    print("\(rank + 1). [\(value)] \(body)  (id \(id), score \(String(format: "%.4f", score)))")
}

func number(_ value: JSONValue?) -> Double? {
    guard let value else { return nil }
    if let integer = value.intValue { return Double(integer) }
    if case .number(let number) = value { return number }
    return nil
}
