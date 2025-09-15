// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudXVungleAdapter",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CloudXVungleAdapter",
            type: .static,
            targets: ["CloudXVungleAdapter"]),
    ],
    dependencies: [
        .package(name: "CloudXCore", path: "../core"),
        .package(url: "https://github.com/Vungle/VungleAdsSDK-SwiftPackageManager.git", from: "7.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CloudXVungleAdapter",
            dependencies: [
                .product(name: "CloudXCore", package: "CloudXCore"),
                .product(name: "VungleAdsSDK", package: "VungleAdsSDK-SwiftPackageManager")
            ],
            path: "Sources/CloudXVungleAdapter",
            swiftSettings: [
                .define("SENTRY_STATIC_LIBRARY")
            ]
        )
    ]
)
