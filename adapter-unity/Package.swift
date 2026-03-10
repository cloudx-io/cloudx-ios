// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudXUnityAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXUnityAdapter",
            type: .static,
            targets: ["CloudXUnityAdapter"]),
    ],
    dependencies: [
        .package(name: "CloudXCore", path: "../core"),
        // Note: UnityAds is CocoaPods-only. SPM builds require manual xcframework integration.
    ],
    targets: [
        .target(
            name: "CloudXUnityAdapter",
            dependencies: [
                .product(name: "CloudXCore", package: "CloudXCore"),
            ],
            path: "Sources/CloudXUnityAdapter"
        )
    ]
)
