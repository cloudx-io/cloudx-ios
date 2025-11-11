// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cloudx-ios",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CloudXCore",
            targets: ["CloudXCore"]
        ),
        .library(
            name: "CloudXMetaAdapter", 
            targets: ["CloudXMetaAdapter"]
        ),
        .library(
            name: "CloudXMediationInMobiAdapter",
            targets: ["CloudXMediationInMobiAdapter"]
        ),
    ],
    targets: [
        // CloudXCore - Source-based target
        .target(
            name: "CloudXCore",
            path: "core/Sources/CloudXCore",
            publicHeadersPath: ".",
            cSettings: [
                .define("DEFINES_MODULE", to: "YES"),
                .define("CLANG_ENABLE_MODULES", to: "YES"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("SafariServices"),
                .linkedFramework("CoreData")
            ]
        ),
        // CloudXMetaAdapter - Binary framework target
        .binaryTarget(
            name: "CloudXMetaAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v1.1.25-meta/CloudXMetaAdapter-v1.1.25.xcframework.zip",
            checksum: "e38d93be3f3cd570c03a4df4a835ce13efa112761764532208fa7bad216416ef"
        ),
        // CloudXMediationInMobiAdapter - Binary framework target
        .binaryTarget(
            name: "CloudXMediationInMobiAdapter",
            url: "https://github.com/cloudx-io/cloudx-ios/releases/download/v1.0.0-inmobi/CloudXMediationInMobiAdapter-v1.0.0.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        )
    ]
)
