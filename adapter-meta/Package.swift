// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudXMetaAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CloudXMetaAdapter",
            type: .static,
            targets: ["CloudXMetaAdapter"]),
    ],
    dependencies: [
        .package(name: "CloudXCore", path: "../cloudexchange.sdk.ios.core"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CloudXMetaAdapter",
            dependencies: [
                .product(name: "CloudXCore", package: "CloudXCore")
            ],
            path: "Sources/CloudXMetaAdapter",
            swiftSettings: [
                .define("SENTRY_STATIC_LIBRARY")
            ]
        )
    ]
)
