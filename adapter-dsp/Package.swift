// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudXDSPAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CloudXDSPAdapter",
            targets: ["CloudXDSPAdapter"]),
    ],
    dependencies: [
        .package(path: "../cloudexchange.sdk.ios.core")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CloudXDSPAdapter",
            dependencies: [.product(name: "CloudXCore", package: "cloudexchange.sdk.ios.core")]),
        .testTarget(
            name: "CloudXDSPAdapterTests",
            dependencies: ["CloudXDSPAdapter"]),
    ]
)
