// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXInMobiAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXInMobiAdapter",
            targets: ["CloudXInMobiAdapter"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXInMobiAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXInMobiAdapter.xcframework.zip",
            checksum: "111b3b11f9e11f4dbc2e081033f877b3b41f7a75967ac9fd9767b1cb0e85c760"
        ),
    ]
)
