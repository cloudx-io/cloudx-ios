// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXCore",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXCore",
            targets: ["CloudXCore"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXCore",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXCore.xcframework.zip",
            checksum: "e215f429a5f7adb4cc26aaf35864a869e5b9150496d4e0977ff07bf048b71774"
        ),
    ]
)
