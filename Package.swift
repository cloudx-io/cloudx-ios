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
//   - CloudXPangleAdapter (underlying Pangle SDK has no official SPM — CocoaPods only)
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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.4/CloudXCore.xcframework.zip",
            checksum: "e4f764467aa9137bb7914e06efe90d28c6bfa1f78e677172ce971f1774ca7e50"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.4/CloudXMetaAdapter.xcframework.zip",
            checksum: "1e7de4d78f40f3f4bdf0590a21be7a2bdba3fe8af708aeabeac04275586340fc"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.4/CloudXVungleAdapter.xcframework.zip",
            checksum: "94ad82c5924bb0beffbffa65156fcfc2542bf45694e875ce5001aa7de613bd10"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.4/CloudXMintegralAdapter.xcframework.zip",
            checksum: "c672214d1819b0565ea74127188df7f01acac7c8d01506b422310775ed470061"
        ),
        .binaryTarget(
            name: "CloudXGoogleWaterfallAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.4/CloudXGoogleWaterfallAdapter.xcframework.zip",
            checksum: "076ad495e725750d43edacef54fb5020321f6fc4c8773c419b23f3c1b891a57f"
        ),
    ]
)
