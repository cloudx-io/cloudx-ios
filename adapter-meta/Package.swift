// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudXMetaAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CloudXMetaAdapter",
            targets: ["CloudXMetaAdapter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/cloudx-xenoss/cloudx-ios.git", from: "1.1.40")
    ],
    targets: [
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-xenoss/cloudx-ios/releases/download/v1.1.25-meta/CloudXMetaAdapter-v1.1.25.xcframework.zip",
            checksum: "1de4dffd27c735d59de48f2c8205cf209e2accc7ecf0cadcf70f14c9b60c068c"
        )
    ]
)
