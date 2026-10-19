import ExampleSupport

// SQL over a collection. Collections are tables in the namespace's SQL catalogue.
let (client, endpoint) = try makeClient()
try await seed(Collections(client))

let queries = [
    "SELECT count(*) AS n FROM kb",
    "SELECT tenant, count(*) AS n FROM kb GROUP BY tenant ORDER BY tenant",
    "SELECT body, tenant FROM kb WHERE tenant = 'a' ORDER BY body",
]
for query in queries {
    print("> \(query)")
    let result = try await runSQL(endpoint: endpoint, query: query)
    print("  \(result.columns.joined(separator: " | "))")
    for row in result.rows {
        print("  " + row.map { $0.stringValue ?? $0.intValue.map(String.init) ?? "\($0)" }.joined(separator: " | "))
    }
}
