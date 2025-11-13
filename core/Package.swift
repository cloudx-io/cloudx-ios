// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CloudXCore",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CloudXCore",
            targets: ["CloudXCore"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "CloudXCore",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v1.1.57-core/CloudXCore.xcframework.zip",
            checksum: "PLACEHOLDER_CHECKSUM_TO_BE_UPDATED_BY_RELEASE_WORKFLOW"
        )
    ]
)



