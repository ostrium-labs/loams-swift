import ExampleSupport
import Foundation
import Loams

// SQL queries through the published loams.sql module. No raw URLSession calls.
let loams = try makeClient()
try await seed(loams)
let queries = [
    ("count", "SELECT count(*) AS n FROM kb", [JSONValue]()),
    ("group by", "SELECT tenant, count(*) AS n FROM kb GROUP BY tenant ORDER BY tenant", [JSONValue]()),
    ("bound value", "SELECT body, tenant FROM kb WHERE tenant = $1 ORDER BY body", [.string("a")]),
    ("hybrid table functions", "SELECT body, _score FROM rrf(vector_search('kb', [1.0, 0.0, 0.0], 'embedding', 10), text_search('kb', 'refund', 'body', 10)) LIMIT 3", [JSONValue]()),
]
for (label, statement, params) in queries {
    print("-- \(label): \(statement)")
    let response = try await loams.sql.query(statement, params: params)
    for row in SqlModule.records(response) { print("  \(row)") }
}
