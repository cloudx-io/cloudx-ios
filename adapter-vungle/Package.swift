// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXVungleAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXVungleAdapter",
            targets: ["CloudXVungleAdapter"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXVungleAdapter.xcframework.zip",
            checksum: "579f3c26007f4c62a971269f4f84a898f0700dac842e362ae32743c6981dda00"
        ),
    ]
)
