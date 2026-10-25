# loams-swift

These examples target **Loams SDK 0.1.2**. Installation and CI require the matching
0.1.2 packages and release tags to be published.

Example apps for the [Loams](https://github.com/ostrium-labs/loams) Swift SDK.

Loams is a single Rust engine for hybrid retrieval: vectors, BM25 full text and filters fused in one planned query, over open formats on object storage. Everything here talks to it over the Connect protocol on the one port an instance serves.

## Install

The SDK is the main repository, versioned by its release tag, so SwiftPM resolves it from git (no registry):

```swift
.package(url: "https://github.com/ostrium-labs/loams.git", exact: "0.1.2")
// target dependency: .product(name: "Loams", package: "loams")
```

## Run the examples

Start a local engine from a checkout of the main repo (or use the compose stack described in [docs/release/preview.md](https://github.com/ostrium-labs/loams/blob/main/docs/release/preview.md)):

```sh
cargo run -p loams -- dev        # serves http://127.0.0.1:8080, auth off
```

Then, with Swift 6.0+:

```sh
swift run quickstart             # connect, create a collection, upsert, hybrid search
swift run sql                    # SQL over the collection
swift run docsearch refund       # a small search CLI
```

Set `LOAMS_ENDPOINT` (default `http://127.0.0.1:8080`) and, if the instance needs one, `LOAMS_API_KEY`. The examples only touch the namespace `examples-swift`.

| Example | What it shows |
|---|---|
| [quickstart](quickstart) | connect, create a collection, upsert documents, hybrid search (vector + BM25 + filter, fused with RRF) |
| [sql](sql) | SQL queries over the collection |
| [app](app) | `docsearch`, a command-line search tool |

## What the SDK covers today

The SDK provides namespaces, collections, documents, search, vector, graph, SQL and streams. `Sources/ExampleSupport` retains examples of dynamic collection RPCs through the SDK invoker and the native SQL HTTP route. SDK app modules can also make these calls directly; see the [Swift SDK](https://github.com/ostrium-labs/loams/tree/v0.1.2/sdks/swift).

## Docs

- https://loams.dev/docs
- [docs/release/preview.md](https://github.com/ostrium-labs/loams/blob/main/docs/release/preview.md)

## License

Apache-2.0
