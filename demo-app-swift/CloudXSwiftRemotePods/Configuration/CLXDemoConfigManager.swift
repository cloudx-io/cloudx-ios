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
    let bannerPlacement: String
    let mrecPlacement: String
    let interstitialPlacement: String
    let nativePlacement: String
    let nativeBannerPlacement: String
    let rewardedPlacement: String
    let rewardedInterstitialPlacement: String
    
    init(appKey: String,
         hashedUserId: String,
         baseURL: String,
         bannerPlacement: String,
         mrecPlacement: String,
         interstitialPlacement: String,
         nativePlacement: String,
         nativeBannerPlacement: String,
         rewardedPlacement: String,
         rewardedInterstitialPlacement: String) {
        
        self.appKey = appKey
        self.hashedUserId = hashedUserId
        self.baseURL = baseURL
        self.bannerPlacement = bannerPlacement
        self.mrecPlacement = mrecPlacement
        self.interstitialPlacement = interstitialPlacement
        self.nativePlacement = nativePlacement
        self.nativeBannerPlacement = nativeBannerPlacement
        self.rewardedPlacement = rewardedPlacement
        self.rewardedInterstitialPlacement = rewardedInterstitialPlacement
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
        // Local Configuration (localhost testing)
        let localConfig = CLXDemoConfig(
            appKey: "E5RotGdN8i7hWhkax1e1o",
            hashedUserId: "test-user-123",
            baseURL: "http://localhost:8090/sdk",
            bannerPlacement: "banner",
            mrecPlacement: "mrec",
            interstitialPlacement: "interstitial",
            nativePlacement: "-",
            nativeBannerPlacement: "-",
            rewardedPlacement: "rewarded",
            rewardedInterstitialPlacement: "rewarded"
        )
        
        // Staging Configuration
        let stagingConfig = CLXDemoConfig(
            appKey: "YG7zqD4RoWwMcGnp3XvNK",
            hashedUserId: "test-user-123-staging",
            baseURL: "https://pro-stage.cloudx.io/sdk",
            bannerPlacement: "swift-demo-banner-1",
            mrecPlacement: "swift-demo-mrec-1",
            interstitialPlacement: "swift-demo-interstitial-1",
            nativePlacement: "-",
            nativeBannerPlacement: "-",
            rewardedPlacement: "-",
            rewardedInterstitialPlacement: "-"
        )
        
        // Dev Configuration (Test app)
        let devConfig = CLXDemoConfig(
            appKey: "E-B3dlMk92hcrUT-9xmMu",
            hashedUserId: "test-user-123",
            baseURL: "https://provisioning-dev.cloudx.io/sdk",
            bannerPlacement: "placement_1",
            mrecPlacement: "place_2",
            interstitialPlacement: "interstitial_home_entry",
            nativePlacement: "-",
            nativeBannerPlacement: "-",
            rewardedPlacement: "objc-demo-rewarded",
            rewardedInterstitialPlacement: "objc-demo-rewarded"
        )
        
        // Production Configuration
        let prodConfig = CLXDemoConfig(
            appKey: "xcQftcBSUmqzuv1LfET2o",
            hashedUserId: "test-user-123",
            baseURL: "https://pro.cloudx.io/sdk",
            bannerPlacement: "swift-demo-banner-1",
            mrecPlacement: "swift-demo-mrec-1",
            interstitialPlacement: "swift-demo-interstitial-1",
            nativePlacement: "-",
            nativeBannerPlacement: "-",
            rewardedPlacement: "-",
            rewardedInterstitialPlacement: "-"
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
