import Foundation

class CLXDemoConfig {
    let appKey: String
    let hashedUserId: String
    let bannerPlacement: String
    let mrecPlacement: String
    let interstitialPlacement: String
    let nativePlacement: String
    let nativeBannerPlacement: String
    let rewardedPlacement: String
    let rewardedInterstitialPlacement: String
    
    init(appKey: String,
         hashedUserId: String,
         bannerPlacement: String,
         mrecPlacement: String,
         interstitialPlacement: String,
         nativePlacement: String,
         nativeBannerPlacement: String,
         rewardedPlacement: String,
         rewardedInterstitialPlacement: String) {
        
        self.appKey = appKey
        self.hashedUserId = hashedUserId
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
    
    // Production configuration for remote pods demo
    let currentConfig: CLXDemoConfig
    
    private init() {
        // Production Configuration (SwiftDemoApp - bundle: cloudx.CloudXSwiftRemotePods)
        self.currentConfig = CLXDemoConfig(
            appKey: "xcQftcBSUmqzuv1LfET2o",
            hashedUserId: "test-user-123",
            bannerPlacement: "swift-demo-banner-1",
            mrecPlacement: "swift-demo-mrec-1",
            interstitialPlacement: "swift-demo-interstitial-1",
            nativePlacement: "-",
            nativeBannerPlacement: "-",
            rewardedPlacement: "-",
            rewardedInterstitialPlacement: "-"
        )
    }
}
