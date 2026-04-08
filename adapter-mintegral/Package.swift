// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXMintegralAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXMintegralAdapter",
            targets: ["CloudXMintegralAdapter"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXMintegralAdapter.xcframework.zip",
            checksum: "010c45e368fe041c4e6852d36318c3b7788a39b657bde78bcdcddf9076b965ca"
        ),
    ]
)
