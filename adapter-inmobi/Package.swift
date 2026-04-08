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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXInMobiAdapter.xcframework.zip",
            checksum: "3fe48aa544d9bb5a6fa3f636b60cd4992c98148c731c5a0e1ba96caadcd39f36"
        ),
    ]
)
