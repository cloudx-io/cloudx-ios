// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

// CloudX iOS SDK — Swift Package Manager distribution
//
// Ships only components whose third-party SDKs have official SPM support:
//   - CloudXCore
//   - CloudXMetaAdapter      (requires github.com/facebook/FBAudienceNetwork)
//   - CloudXVungleAdapter    (requires github.com/Vungle/VungleAdsSDK-SwiftPackageManager)
//   - CloudXMintegralAdapter (requires github.com/Mintegral-official/MintegralAdSDK-Swift-Package)
//   - CloudXGoogleWaterfallAdapter (requires github.com/googleads/swift-package-manager-google-mobile-ads)
//
// NOT included (use CocoaPods instead — CocoaPods+SPM hybrid is supported):
//   - CloudXInMobiAdapter (no official InMobiSDK SPM)
//   - CloudXUnityAdsAdapter (no official UnityAds SPM)
//   - CloudXMagniteAdapter / CloudXMolocoAdapter / CloudXVerveAdapter (SPM not yet validated against the shipped binary)
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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.3/CloudXCore.xcframework.zip",
            checksum: "25a6cb2753d7422c0447288649fd80b2ca951ed154d44ea53330121f865733e6"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.3/CloudXMetaAdapter.xcframework.zip",
            checksum: "7cde3420f2f5a62460812a8e74d00c7552c6c7f975d2ad98f72e74ff2f6d0a77"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.3/CloudXVungleAdapter.xcframework.zip",
            checksum: "083b50f52a89c364ce1cf2977b8a27986af9e712c86a9899c77c8a63a2c9197f"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.3/CloudXMintegralAdapter.xcframework.zip",
            checksum: "43884e69a7598ebb5b6efb21b21de8f08e426d5678309f6d477d328bddc9cc59"
        ),
        .binaryTarget(
            name: "CloudXGoogleWaterfallAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.3/CloudXGoogleWaterfallAdapter.xcframework.zip",
            checksum: "b4a3d0dce2fdf73a877fb8984af2c9a2a67d08fdca0b3e01475d09117358bedc"
        ),
    ]
)
