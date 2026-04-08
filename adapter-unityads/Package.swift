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
            checksum: "f51c1cb378ec3dbea9a7e9426bfcccc92710178f2b4cb6166edd5939da2b822a"
        ),
    ]
)
