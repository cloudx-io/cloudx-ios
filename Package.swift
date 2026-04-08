// swift-tools-version: 5.9
// Requires Xcode 15+
import PackageDescription

let package = Package(
    name: "CloudX",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "CloudXCore", targets: ["CloudXCore"]),
        .library(name: "CloudXMetaAdapter", targets: ["CloudXMetaAdapter"]),
        .library(name: "CloudXVungleAdapter", targets: ["CloudXVungleAdapter"]),
        .library(name: "CloudXInMobiAdapter", targets: ["CloudXInMobiAdapter"]),
        .library(name: "CloudXMintegralAdapter", targets: ["CloudXMintegralAdapter"]),
        .library(name: "CloudXUnityAdsAdapter", targets: ["CloudXUnityAdsAdapter"]),
        .library(name: "CloudXRenderer", targets: ["CloudXRenderer"]),
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
            name: "CloudXInMobiAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXInMobiAdapter.xcframework.zip",
            checksum: "111b3b11f9e11f4dbc2e081033f877b3b41f7a75967ac9fd9767b1cb0e85c760"
        ),
        .binaryTarget(
            name: "CloudXMintegralAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXMintegralAdapter.xcframework.zip",
            checksum: "010c45e368fe041c4e6852d36318c3b7788a39b657bde78bcdcddf9076b965ca"
        ),
        .binaryTarget(
            name: "CloudXUnityAdsAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXUnityAdsAdapter.xcframework.zip",
            checksum: "cbe0e95035dd0cdfb5cf95d09e751d064592b28a59b52e86dde2810a928f5db8"
        ),
        .binaryTarget(
            name: "CloudXRenderer",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v2.2.8/CloudXRenderer.xcframework.zip",
            checksum: "b9656cfb5382389c5445bec9dbd80a6b7e45993c336ea0ad52fb85a02215a94f"
        ),
    ]
)
