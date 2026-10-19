// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "loams-swift-examples",
    platforms: [.macOS(.v12)],
    dependencies: [
        // The Loams Swift SDK is the main repository, versioned by its release tag.
        .package(url: "https://github.com/ostrium-labs/loams.git", exact: "0.1.0"),
    ],
    targets: [
        // Small helpers shared by the examples: the collection, document and
        // search calls the SDK facade does not wrap yet, plus the SQL route.
        .target(
            name: "ExampleSupport",
            dependencies: [.product(name: "Loams", package: "loams")],
            path: "Sources/ExampleSupport"
        ),
        .executableTarget(
            name: "quickstart",
            dependencies: ["ExampleSupport", .product(name: "Loams", package: "loams")],
            path: "quickstart"
        ),
        .executableTarget(
            name: "sql",
            dependencies: ["ExampleSupport", .product(name: "Loams", package: "loams")],
            path: "sql"
        ),
        .executableTarget(
            name: "docsearch",
            dependencies: ["ExampleSupport", .product(name: "Loams", package: "loams")],
            path: "app"
        ),
    ],
    swiftLanguageVersions: [.v6]
)
