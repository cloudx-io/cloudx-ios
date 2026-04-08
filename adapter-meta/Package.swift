// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXMetaAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXMetaAdapter",
            targets: ["CloudXMetaAdapter"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXMetaAdapter.xcframework.zip",
            checksum: "4a68885ab13929b681a86ea0a48cb56b35f9d79bb354b37318f21e0d4a9b50e9"
        ),
    ]
)
