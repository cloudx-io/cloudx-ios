import Foundation

class CLXDemoConfig {
    let appKey: String
    let hashedUserId: String
    let bannerAdUnitId: String
    let mrecAdUnitId: String
    let interstitialAdUnitId: String
    let nativeAdUnitId: String
    let nativeBannerAdUnitId: String
    let rewardedAdUnitId: String
    let rewardedInterstitialAdUnitId: String
    
    init(appKey: String,
         hashedUserId: String,
         bannerAdUnitId: String,
         mrecAdUnitId: String,
         interstitialAdUnitId: String,
         nativeAdUnitId: String,
         nativeBannerAdUnitId: String,
         rewardedAdUnitId: String,
         rewardedInterstitialAdUnitId: String) {
        
        self.appKey = appKey
        self.hashedUserId = hashedUserId
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
    
    // Production configuration for remote pods demo
    let currentConfig: CLXDemoConfig
    
    private init() {
        // Production Configuration (SwiftDemoApp - bundle: cloudx.CloudXSwiftRemotePods)
        self.currentConfig = CLXDemoConfig(
            appKey: "xcQftcBSUmqzuv1LfET2o",
            hashedUserId: "test-user-123",
            bannerAdUnitId: "swift-demo-banner-1",
            mrecAdUnitId: "swift-demo-mrec-1",
            interstitialAdUnitId: "swift-demo-interstitial-1",
            nativeAdUnitId: "-",
            nativeBannerAdUnitId: "-",
            rewardedAdUnitId: "-",
            rewardedInterstitialAdUnitId: "-"
        )
    }
}
