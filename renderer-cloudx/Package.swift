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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXRenderer.xcframework.zip",
            checksum: "b9656cfb5382389c5445bec9dbd80a6b7e45993c336ea0ad52fb85a02215a94f"
        ),
    ]
)
