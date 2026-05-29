// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

// CloudX iOS SDK — Swift Package Manager distribution
//
// Ships only components whose third-party SDKs have official SPM support:
//   - CloudXCore
//   - CloudXMetaAdapter            (requires github.com/facebook/FBAudienceNetwork)
//   - CloudXVungleAdapter          (requires github.com/Vungle/VungleAdsSDK-SwiftPackageManager)
//   - CloudXMintegralAdapter       (requires github.com/Mintegral-official/MintegralAdSDK-Swift-Package)
//   - CloudXGoogleWaterfallAdapter (requires github.com/googleads/swift-package-manager-google-mobile-ads)
//
// NOT included (use CocoaPods instead — CocoaPods+SPM hybrid is supported):
//   - CloudXInMobiAdapter (no official InMobiSDK SPM)
//   - CloudXUnityAdsAdapter (no official UnityAds SPM)
//   - CloudXMagniteAdapter (no official MagniteSDK SPM)
//   - CloudXMolocoAdapter (MolocoSDKiOS SPM not yet validated against this binary)
//   - CloudXVerveAdapter (HyBid SPM not yet validated against this binary)
//   - CloudXRenderer (being merged into Core)

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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.2/CloudXCore.xcframework.zip",
            checksum: "c71654949333d34b61e41c34ba4ebeef60bd7ee9264d848ca605f66296267f50"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.2/CloudXMetaAdapter.xcframework.zip",
            checksum: "79b90535a7cce144a23a3deee330464ac8184543a5b9e474ce54a7f6854f090c"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.2/CloudXVungleAdapter.xcframework.zip",
            checksum: "ade7c67cb29cc5a9af35f390a88c3e14aa32b9760177a7be0f1297f89c770a3b"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.2/CloudXMintegralAdapter.xcframework.zip",
            checksum: "12b29a31f651f73ea27b88c3fa005e9db680c91a1b180e4652b8a1e05a6662af"
        ),
        .binaryTarget(
            name: "CloudXGoogleWaterfallAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.2/CloudXGoogleWaterfallAdapter.xcframework.zip",
            checksum: "cf4d57ef42c7dadd75c4234d6f6ea6bdb673fb0669dfeb50599a2ca1bc309b2a"
        ),
    ]
)
