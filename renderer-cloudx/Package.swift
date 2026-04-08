// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXRenderer",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXRenderer",
            targets: ["CloudXRenderer"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXRenderer",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXRenderer.xcframework.zip",
            checksum: "f00ec49f11d24297169cb2f011647cae955a274890634639d2acc50483cf28ef"
        ),
    ]
)
