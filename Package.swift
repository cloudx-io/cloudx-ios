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
            checksum: "45a78dc6a58a844ec33fab853642d823bddd0c16d929a89c66c1c30113f0a99f"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXMetaAdapter.xcframework.zip",
            checksum: "5819a786e213636396d08126051b4f26322ffd00c41a5957813a0b9b14176a6b"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXVungleAdapter.xcframework.zip",
            checksum: "8e9f08572cd7a4a036d55999d695646d4c667cbeb561b2b7a3b8cf7cd9de9a2b"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXMintegralAdapter.xcframework.zip",
            checksum: "fc16d8cc198053e934a5aef0adaa479b5875c9b79915fc15ae643b325529d375"
        ),
        .binaryTarget(
            name: "CloudXGoogleWaterfallAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.5/CloudXGoogleWaterfallAdapter.xcframework.zip",
            checksum: "5dece9297c987d4dc92cda5b156f0c8686ec5f4aa3b1e11071961b66b0a33ea3"
        ),
    ]
)
