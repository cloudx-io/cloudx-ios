// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CloudXMintegralAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CloudXMintegralAdapter",
            targets: ["CloudXMintegralAdapter"]),
    ],
    dependencies: [
        .package(name: "CloudXCore", path: "../cloudexchange.sdk.ios.core"),
        .package(url: "https://github.com/Mintegral-official/MintegralAdSDK-Swift-Package.git",  .upToNextMajor(from:"7.6.8"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CloudXMintegralAdapter",
            dependencies: [
                .product(name: "CloudXCore", package: "CloudXCore"),
                .product(name: "MintegralAdSDK", package: "MintegralAdSDK-Swift-Package")
//                .targetItem(name: "MTGSDK", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKBanner", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKBidding", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKInterstitialVideo", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKNativeAdvanced", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKNewInterstitial", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKReward", condition: .when(platforms: [.iOS])),
//                .targetItem(name: "MTGSDKSplash", condition: .when(platforms: [.iOS])),
            ]
        ),
//        .binaryTarget(name: "MTGSDK", path: "./Sources/Fmk/MTGSDK.xcframework"),
//        .binaryTarget(name: "MTGSDKBanner", path: "./Sources/Fmk/MTGSDKBanner.xcframework"),
//        .binaryTarget(name: "MTGSDKBidding", path: "./Sources/Fmk/MTGSDKBidding.xcframework"),
//        .binaryTarget(name: "MTGSDKInterstitialVideo", path: "./Sources/Fmk/MTGSDKInterstitialVideo.xcframework"),
//        .binaryTarget(name: "MTGSDKNativeAdvanced", path: "./Sources/Fmk/MTGSDKNativeAdvanced.xcframework"),
//        .binaryTarget(name: "MTGSDKNewInterstitial", path: "./Sources/Fmk/MTGSDKNewInterstitial.xcframework"),
//        .binaryTarget(name: "MTGSDKReward", path: "./Sources/Fmk/MTGSDKReward.xcframework"),
//        .binaryTarget(name: "MTGSDKSplash", path: "./Sources/Fmk/MTGSDKSplash.xcframework"),
        .testTarget(
            name: "CloudXMintegralAdapterTests",
            dependencies: ["CloudXMintegralAdapter"]),
    ]
)
