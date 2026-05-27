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
        // Production Configuration (shared with ObjC demo - bundle: cloudx.CloudXObjCRemotePods)
        // Both demos share the same SSP-side appKey, ad units, and bundle ID — they're the
        // same logical app, two language implementations. Only one can be installed per
        // simulator at a time (uninstall the other before installing).
        self.currentConfig = CLXDemoConfig(
            appKey: "ihtOXvp3X9JlMQ5p0_RYL",
            hashedUserId: "test-user-123",
            bannerAdUnitId: "LyPxKhBFiUCd1xMLYQhGc",
            mrecAdUnitId: "EWaeXDSmKYbs220gM5hTv",
            interstitialAdUnitId: "txZ7NmISq-MsuPH0ULKbD",
            nativeAdUnitId: "Q33RbPmBH-wix45Mu6--Z",
            nativeBannerAdUnitId: "-2_Lw2b4QTlu7x6tKZ6Ww",
            rewardedAdUnitId: "um9Ek08ScJBWuzSMTyW3b",
            rewardedInterstitialAdUnitId: "I-JRnXEQc2bG5dm1EWoZ6"
        )
    }
}
