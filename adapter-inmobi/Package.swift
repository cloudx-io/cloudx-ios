// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudXMediationInMobiAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CloudXMediationInMobiAdapter",
            targets: ["CloudXMediationInMobiAdapter"]
        ),
    ],
    dependencies: [
        .package(path: "../core")
    ],
    targets: [
        .target(
            name: "CloudXMediationInMobiAdapter",
            dependencies: [],
            path: "Sources/CloudXMediationInMobiAdapter",
            publicHeadersPath: ".",
            cSettings: [
                .define("DEFINES_MODULE", to: "YES"),
                .define("CLANG_ENABLE_MODULES", to: "YES"),
                .headerSearchPath("."),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit"),
                .linkedFramework("AdSupport"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreTelephony"),
                .linkedFramework("StoreKit"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("WebKit"),
                .linkedFramework("AppTrackingTransparency", .when(platforms: [.iOS])),
            ]
        ),
    ]
)

