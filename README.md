# loams-swift

These examples target the published **Loams SDK 0.1.2** release, resolved by
Swift Package Manager from the `v0.1.2` Git tag.

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

Set `LOAMS_ENDPOINT` to the instance base URL (for a local dev engine, `http://127.0.0.1:8080`) and, if the instance needs one, `LOAMS_API_KEY`. The SDK requires the endpoint variable. The examples only touch the namespace `examples-swift`.

| Example | What it shows |
|---|---|
| [quickstart](quickstart) | instance/system, namespaces, collections, documents, text/vector/hybrid search, optional graph, SDK SQL and streams |
| [sql](sql) | SQL module: selects, parameters, aggregates and hybrid table functions |
| [app](app) | `docsearch`, a CLI using the SDK search and vector builders/modules |

## What the SDK covers today

The examples use the published high-level app modules and builders throughout. `Sources/ExampleSupport` only creates the example client and seeds the sample collection through those modules; there are no direct `URLSession` SQL calls or hand-built collection RPC bindings. SDK Live and system modules remain part of the package; the quickstart demonstrates system and optional-feature discovery. See the [Swift SDK Notes example](https://github.com/ostrium-labs/loams/blob/v0.1.2/sdks/swift/Examples/Notes/Notes.swift) for the same signatures.

## Docs

- https://loams.dev/docs
- [docs/release/preview.md](https://github.com/ostrium-labs/loams/blob/main/docs/release/preview.md)

## License

Apache-2.0
