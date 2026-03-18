// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudXUnityAdsAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXUnityAdsAdapter",
            type: .static,
            targets: ["CloudXUnityAdsAdapter"]),
    ],
    dependencies: [
        .package(name: "CloudXCore", path: "../core"),
        // Note: UnityAds is CocoaPods-only. SPM builds require manual xcframework integration.
    ],
    targets: [
        .target(
            name: "CloudXUnityAdsAdapter",
            dependencies: [
                .product(name: "CloudXCore", package: "CloudXCore"),
            ],
            path: "Sources/CloudXUnityAdsAdapter"
        )
    ]
)
