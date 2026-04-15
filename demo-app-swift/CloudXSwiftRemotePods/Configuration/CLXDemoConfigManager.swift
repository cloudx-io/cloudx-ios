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
            bannerAdUnitId: "Ce5-ltAX5zFz5QJ3TzEjY",
            mrecAdUnitId: "xMLHNFIkwieu2SLyeD0sQ",
            interstitialAdUnitId: "rkw0ncj6mSphKtmnl8Cw_",
            nativeAdUnitId: "Q33RbPmBH-wix45Mu6--Z",
            nativeBannerAdUnitId: "-2_Lw2b4QTlu7x6tKZ6Ww",
            rewardedAdUnitId: "WJje0XGqL5n56Sa8dlt8L",
            rewardedInterstitialAdUnitId: "-"
        )
    }
}
