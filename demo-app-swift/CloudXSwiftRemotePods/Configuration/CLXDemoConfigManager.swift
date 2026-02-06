import Foundation

enum CLXDemoEnvironment: Int {
    case local = 0
    case dev = 1
    case staging = 2
    case production = 3
}

class CLXDemoConfig {
    let appKey: String
    let hashedUserId: String
    let baseURL: String
    let bannerAdUnitId: String
    let mrecAdUnitId: String
    let interstitialAdUnitId: String
    let nativeAdUnitId: String
    let nativeBannerAdUnitId: String
    let rewardedAdUnitId: String
    let rewardedInterstitialAdUnitId: String
    
    init(appKey: String,
         hashedUserId: String,
         baseURL: String,
         bannerAdUnitId: String,
         mrecAdUnitId: String,
         interstitialAdUnitId: String,
         nativeAdUnitId: String,
         nativeBannerAdUnitId: String,
         rewardedAdUnitId: String,
         rewardedInterstitialAdUnitId: String) {
        
        self.appKey = appKey
        self.hashedUserId = hashedUserId
        self.baseURL = baseURL
        self.bannerAdUnitId = bannerAdUnitId
        self.mrecAdUnitId = mrecAdUnitId
        self.interstitialAdUnitId = interstitialAdUnitId
        self.nativeAdUnitId = nativeAdUnitId
        self.nativeBannerAdUnitId = nativeBannerAdUnitId
        self.rewardedAdUnitId = rewardedAdUnitId
        self.rewardedInterstitialAdUnitId = rewardedInterstitialAdUnitId
    }
}

class CLXDemoConfigManager {
    static let sharedManager = CLXDemoConfigManager()
    
    var currentEnvironment: CLXDemoEnvironment = .production
    private let configurations: [CLXDemoEnvironment: CLXDemoConfig]
    
    var currentConfig: CLXDemoConfig {
        return configForEnvironment(currentEnvironment)
    }
    
    private init() {
        // ==========================================================================
        // IMPORTANT: Ad unit identifiers must be the CloudX ad unit ID (not name)
        // The SDK now uses ad unit IDs for lookup (matching Android SDK behavior).
        // Get IDs from: CloudX dashboard or server config response's adUnits[].id
        // Example ID format: "um9Ek08ScJBWuzSMTyW3b" (not "demo-banner-1")
        // ==========================================================================

        // Local Configuration (localhost testing)
        // TODO: Replace ad unit names with actual IDs from local server config
        let localConfig = CLXDemoConfig(
            appKey: "E5RotGdN8i7hWhkax1e1o",
            hashedUserId: "test-user-123",
            baseURL: "http://localhost:8090/sdk",
            bannerAdUnitId: "banner",
            mrecAdUnitId: "mrec",
            interstitialAdUnitId: "interstitial",
            nativeAdUnitId: "-",
            nativeBannerAdUnitId: "-",
            rewardedAdUnitId: "rewarded",
            rewardedInterstitialAdUnitId: "rewarded"
        )

        // Staging Configuration
        // TODO: Replace ad unit names with actual IDs from staging server config
        let stagingConfig = CLXDemoConfig(
            appKey: "YG7zqD4RoWwMcGnp3XvNK",
            hashedUserId: "test-user-123-staging",
            baseURL: "https://pro-stage.cloudx.io/sdk",
            bannerAdUnitId: "swift-demo-banner-1",
            mrecAdUnitId: "swift-demo-mrec-1",
            interstitialAdUnitId: "swift-demo-interstitial-1",
            nativeAdUnitId: "-",
            nativeBannerAdUnitId: "-",
            rewardedAdUnitId: "-",
            rewardedInterstitialAdUnitId: "-"
        )

        // Dev Configuration (Test app)
        // TODO: Replace ad unit names with actual IDs from dev server config
        let devConfig = CLXDemoConfig(
            appKey: "E-B3dlMk92hcrUT-9xmMu",
            hashedUserId: "test-user-123",
            baseURL: "https://provisioning-dev.cloudx.io/sdk",
            bannerAdUnitId: "placement_1",
            mrecAdUnitId: "place_2",
            interstitialAdUnitId: "interstitial_home_entry",
            nativeAdUnitId: "-",
            nativeBannerAdUnitId: "-",
            rewardedAdUnitId: "objc-demo-rewarded",
            rewardedInterstitialAdUnitId: "objc-demo-rewarded"
        )

        // Production Configuration
        let prodConfig = CLXDemoConfig(
            appKey: "xcQftcBSUmqzuv1LfET2o",
            hashedUserId: "test-user-123",
            baseURL: "https://pro.cloudx.io/sdk",
            bannerAdUnitId: "LyPxKhBFiUCd1xMLYQhGc",
            mrecAdUnitId: "EWaeXDSmKYbs220gM5hTv",
            interstitialAdUnitId: "txZ7NmISq-MsuPH0ULKbD",
            nativeAdUnitId: "Q33RbPmBH-wix45Mu6--Z",
            nativeBannerAdUnitId: "-",
            rewardedAdUnitId: "-",
            rewardedInterstitialAdUnitId: "-"
        )
        
        self.configurations = [
            .local: localConfig,
            .dev: devConfig,
            .staging: stagingConfig,
            .production: prodConfig
        ]
    }
    
    func setEnvironment(_ environment: CLXDemoEnvironment) {
        currentEnvironment = environment
    }
    
    func configForEnvironment(_ environment: CLXDemoEnvironment) -> CLXDemoConfig {
        return configurations[environment]!
    }
    
    func environmentName(_ environment: CLXDemoEnvironment) -> String {
        switch environment {
        case .local:
            return "Local"
        case .dev:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
    
    var buildSchemeName: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
    
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    func enhancedErrorMessage(for environment: CLXDemoEnvironment, originalError: String) -> String {
        let isDebug = isDebugBuild
        let buildScheme = buildSchemeName
        let envName = environmentName(environment)
        
        if originalError.contains("Unauthorized") ||
           originalError.contains("Invalid app key") ||
           originalError.contains("malformed App Key") {
            
            if environment == .production && isDebug {
                return "Production init failed: Build scheme is set to '\(buildScheme)' but trying to use Production environment. Please switch to Release build scheme for Production, or use Dev/Staging environments with Debug builds.\n\nOriginal error: \(originalError)"
            }
            
            if environment != .production && !isDebug {
                return "\(envName) init failed: Build scheme is set to '\(buildScheme)' but trying to use \(envName) environment. Debug environments (Dev/Staging) require Debug build scheme, or switch to Production environment with Release builds.\n\nOriginal error: \(originalError)"
            }
            
            return "\(envName) init failed with error: \(originalError)\n\nCurrent build scheme: \(buildScheme)\nEnvironment: \(envName)"
        }
        
        return originalError
    }
}
