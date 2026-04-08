// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudXUnityAdsAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXUnityAdsAdapter",
            targets: ["CloudXUnityAdsAdapter"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXUnityAdsAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8.1/CloudXUnityAdsAdapter.xcframework.zip",
            checksum: "cbe0e95035dd0cdfb5cf95d09e751d064592b28a59b52e86dde2810a928f5db8"
        ),
    ]
)
