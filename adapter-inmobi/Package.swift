// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudXInMobiAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CloudXInMobiAdapter",
            targets: ["CloudXInMobiAdapter"]
        ),
    ],
    dependencies: [
        .package(path: "../core")
    ],
    targets: [
        .target(
            name: "CloudXInMobiAdapter",
            dependencies: [],
            path: "Sources/CloudXInMobiAdapter",
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

