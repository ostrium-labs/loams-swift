# loams-swift

Example apps for the [Loams](https://github.com/ostrium-labs/loams) Swift SDK.

Loams is a single Rust engine for hybrid retrieval: vectors, BM25 full text and filters fused in one planned query, over open formats on object storage. Everything here talks to it over the Connect protocol on the one port an instance serves.

## Install

The SDK is the main repository, versioned by its release tag, so SwiftPM resolves it from git (no registry):

```swift
.package(url: "https://github.com/ostrium-labs/loams.git", exact: "0.1.0")
// target dependency: .product(name: "Loams", package: "loams")
```

## Run the examples

Start a local engine from a checkout of the main repo (or use the compose stack described in [docs/release/preview.md](https://github.com/ostrium-labs/loams/blob/main/docs/release/preview.md)):

```sh
cargo run -p loams -- dev        # serves http://127.0.0.1:18080, auth off
```

Then, with Swift 6.0+:

```sh
swift run quickstart             # connect, create a collection, upsert, hybrid search
swift run sql                    # SQL over the collection
swift run docsearch refund       # a small search CLI
```

Set `LOAMS_ENDPOINT` (default `http://127.0.0.1:18080`) and, if the instance needs one, `LOAMS_API_KEY`. The examples only touch the namespace `examples-swift`.

| Example | What it shows |
|---|---|
| [quickstart](quickstart) | connect, create a collection, upsert documents, hybrid search (vector + BM25 + filter, fused with RRF) |
| [sql](sql) | SQL queries over the collection |
| [app](app) | `docsearch`, a command-line search tool |

## What the SDK covers today

The 0.1.0 Swift SDK's typed facade covers `instance`, `live` and `tables`. It has no collection, document, search or SQL module yet. `Sources/ExampleSupport` therefore makes those calls itself:

- Collection, document and search RPCs go through the SDK's own `CallInvoker` (auth, retries, error mapping) with hand-built `CallBinding`s for `loams.collection.v1`.
- SQL has no Connect RPC, so it posts to the engine's REST route `/v1/namespaces/<ns>/sql` with `URLSession`.

When the SDK grows those modules, `ExampleSupport` shrinks to nothing.

## Docs

- https://loams.dev/docs
- [docs/release/preview.md](https://github.com/ostrium-labs/loams/blob/main/docs/release/preview.md)

## License

Apache-2.0
