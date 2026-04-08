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
            checksum: "343a928bf90d82aa2517d5e0137039ae401478870c8c747f25fa51c3be870026"
        ),
    ]
)
