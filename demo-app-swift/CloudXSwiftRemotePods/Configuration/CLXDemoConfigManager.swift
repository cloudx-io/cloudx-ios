import Foundation

enum CLXDemoEnvironment: Int {
    case dev = 0
    case staging = 1
    case production = 2
}

class CLXDemoConfig {
    let appId: String
    let hashedUserId: String
    let baseURL: String
    let bannerPlacement: String
    let mrecPlacement: String
    let interstitialPlacement: String
    let nativePlacement: String
    let nativeBannerPlacement: String
    let rewardedPlacement: String
    let rewardedInterstitialPlacement: String
    
    init(appId: String,
         hashedUserId: String,
         baseURL: String,
         bannerPlacement: String,
         mrecPlacement: String,
         interstitialPlacement: String,
         nativePlacement: String,
         nativeBannerPlacement: String,
         rewardedPlacement: String,
         rewardedInterstitialPlacement: String) {
        
        self.appId = appId
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
    
    var currentEnvironment: CLXDemoEnvironment = .dev
    private let configurations: [CLXDemoEnvironment: CLXDemoConfig]
    
    var currentConfig: CLXDemoConfig {
        return configForEnvironment(currentEnvironment)
    }
    
    private init() {
        // Dev Configuration (current production values)
        let devConfig = CLXDemoConfig(
            appId: "g0PdN9_0ilfIcuNXhBopl",
            hashedUserId: "test-user-123",
            baseURL: "https://pro-dev.cloudx.io/sdk",
            bannerPlacement: "metaBanner",
            mrecPlacement: "metaMREC",
            interstitialPlacement: "metaInterstitial",
            nativePlacement: "metaNative",
            nativeBannerPlacement: "metaNative",
            rewardedPlacement: "metaRewarded",
            rewardedInterstitialPlacement: "metaRewarded"
        )
        
        // Staging Configuration
        let stagingConfig = CLXDemoConfig(
            appId: "9o_9omGptuyS2n5wV0QJu",
            hashedUserId: "test-user-123-staging",
            baseURL: "https://pro-stage.cloudx.io/sdk",
            bannerPlacement: "metaBanner",
            mrecPlacement: "metaMREC",
            interstitialPlacement: "metaInterstitial",
            nativePlacement: "metaNative",
            nativeBannerPlacement: "metaNative",
            rewardedPlacement: "metaRewarded",
            rewardedInterstitialPlacement: "metaRewarded"
        )
        
        // Production Configuration (placeholders)
        let prodConfig = CLXDemoConfig(
            appId: "PROD_APP_ID_PLACEHOLDER",
            hashedUserId: "prod-user-placeholder",
            baseURL: "https://pro.cloudx.io/sdk",
            bannerPlacement: "prodBanner",
            mrecPlacement: "prodMREC",
            interstitialPlacement: "prodInterstitial",
            nativePlacement: "prodNative",
            nativeBannerPlacement: "prodNative",
            rewardedPlacement: "prodRewarded",
            rewardedInterstitialPlacement: "prodRewarded"
        )
        
        self.configurations = [
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
        case .dev:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}