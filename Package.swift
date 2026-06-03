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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXCore.xcframework.zip",
            checksum: "b03844d378cb7bce454e96781fc0fa838ff7a30a0e335cf4b9ed883464887108"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXMetaAdapter.xcframework.zip",
            checksum: "7097ace709f4adf8ad6d122350ae99dcb9ef735a6850a0e6e30209a03fe3edf6"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXVungleAdapter.xcframework.zip",
            checksum: "762d6c63f7c3f8f47e3cc84da4b4cbb5b2cd0881dae4f90c18d91bccf9a5e928"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXMintegralAdapter.xcframework.zip",
            checksum: "e1816a386e4e461a49222ded9e35b0325e199a923b52758bbe348f807a096779"
        ),
        .binaryTarget(
            name: "CloudXGoogleWaterfallAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXGoogleWaterfallAdapter.xcframework.zip",
            checksum: "35a6348b7fc7c66dd004b94ee5d57d1318799d578a05836174d54bf0508775a5"
        ),
    ]
)
