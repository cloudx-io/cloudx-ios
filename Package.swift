// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

// CloudX iOS SDK — Swift Package Manager distribution
//
// This package ships only the components whose third-party SDK dependencies
// have official SPM support:
//   - CloudXCore
//   - CloudXMetaAdapter      (requires github.com/facebook/FBAudienceNetwork)
//   - CloudXVungleAdapter    (requires github.com/Vungle/VungleAdsSDK-SwiftPackageManager)
//   - CloudXMintegralAdapter (requires github.com/Mintegral-official/MintegralAdSDK-Swift-Package)
//
// NOT included (no official SPM for the underlying SDK — use CocoaPods instead):
//   - CloudXInMobiAdapter
//   - CloudXUnityAdsAdapter
//   - CloudXRenderer (being merged into Core)
//
// CocoaPods + SPM hybrid in the same project is supported by Xcode.

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
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXCore.xcframework.zip",
            checksum: "e215f429a5f7adb4cc26aaf35864a869e5b9150496d4e0977ff07bf048b71774"
        ),
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXMetaAdapter.xcframework.zip",
            checksum: "fe8c78b47fffcd03dd100177d990f3e50241c7db54062a4af5db627c91c807a6"
        ),
        .binaryTarget(
            name: "CloudXVungleAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXVungleAdapter.xcframework.zip",
            checksum: "7e1d736b04874ea1c6c25f25f93d4298f618478a982f4b6d0a8f2dc4eaaa595a"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXMintegralAdapter.xcframework.zip",
            checksum: "010c45e368fe041c4e6852d36318c3b7788a39b657bde78bcdcddf9076b965ca"
        ),
    ]
)
