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
            checksum: "fe8c78b47fffcd03dd100177d990f3e50241c7db54062a4af5db627c91c807a6"
        ),
    ]
)
