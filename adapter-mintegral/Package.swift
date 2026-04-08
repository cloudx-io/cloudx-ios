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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXMintegralAdapter.xcframework.zip",
            checksum: "46e7df04e505404edf3cf0edbeebe6e9308cd421fc24dd175d7332103c127a01"
        ),
    ]
)
