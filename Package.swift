// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

// DEPRECATED: this package is frozen at CloudX iOS SDK 3.4.6 and receives no updates.
//
// Each CloudX component now ships as its own Swift package, for example
// https://github.com/cloudx-io/cloudx-ios-swift-package-core.git
// The Swift Package Manager guide lists every package and its latest version:
// https://docs.cloudx.io/en/ios/swift-package-manager

let package = Package(
    name: "CloudX",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "CloudXCore", targets: ["CloudXCore"]),
        .library(name: "CloudXMetaAdapter", targets: ["CloudXMetaAdapter"]),
        .library(name: "CloudXVungleAdapter", targets: ["CloudXVungleAdapter"]),
        .library(name: "CloudXMintegralAdapter", targets: ["CloudXMintegralAdapter"]),
        .library(name: "CloudXGoogleWaterfallAdapter", targets: ["CloudXGoogleWaterfallAdapter"]),
    ],
    targets: [
        .binaryTarget(
            name: "CloudXCore",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.6/CloudXCore.xcframework.zip",
            checksum: "9733fdce40d196e4ead298e438385092453cf56023dd725358523f8bc491bc3e"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.6/CloudXMetaAdapter.xcframework.zip",
            checksum: "df0356aee1b6bf981cde6456fcd8869dd6a030dab4700d2c1f3c56f7dbe21c52"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.6/CloudXVungleAdapter.xcframework.zip",
            checksum: "c2b5cdc35f305d463e6c93a10ceb8811f9e08c12bc0838f232e4787279ebc334"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.6/CloudXMintegralAdapter.xcframework.zip",
            checksum: "ad8ae073b9a1c00e4ca1c462b4e0d87a027bb213895ffaab04f5e6553c8683fc"
        ),
        .binaryTarget(
            name: "CloudXGoogleWaterfallAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.6/CloudXGoogleWaterfallAdapter.xcframework.zip",
            checksum: "853199f40699e7da71727715662b136377e965e5c90a4797cf5447d2a833a74e"
        ),
    ]
)
