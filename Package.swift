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
    ],
    targets: [
        .binaryTarget(
            name: "CloudXCore",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.1/CloudXCore.xcframework.zip",
            checksum: "96f99ca98b0654a66a64bc7021a7a0e19e05704a3ee100a6498a72323024ba23"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.1/CloudXMetaAdapter.xcframework.zip",
            checksum: "b10aeecbc24e6fc3a66d06560f08e6156d4d1f3bd50e4e42f42febe0c2360fe4"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.1/CloudXVungleAdapter.xcframework.zip",
            checksum: "5064a0c3ff6eef8905587efd31d852b6cfb9e9168c68ce7774a2a69e0ee7f1c8"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v3.4.1/CloudXMintegralAdapter.xcframework.zip",
            checksum: "83d41c4753efd97d0b2f67cf63d43b2f6d52fa756fd93868d553fc90a2c2ea66"
        ),
    ]
)
