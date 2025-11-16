// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudXMolocoAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CloudXMolocoAdapter",
            targets: ["CloudXMolocoAdapter"]
        ),
    ],
    dependencies: [
        .package(path: "../core")
    ],
    targets: [
        .target(
            name: "CloudXMolocoAdapter",
            dependencies: [],
            path: "Sources/CloudXMolocoAdapter",
            publicHeadersPath: ".",
            cSettings: [
                .define("DEFINES_MODULE", to: "YES"),
                .define("CLANG_ENABLE_MODULES", to: "YES"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit"),
                .linkedFramework("AdSupport"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreTelephony"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("AppTrackingTransparency", .when(platforms: [.iOS])),
            ]
        ),
    ]
)

