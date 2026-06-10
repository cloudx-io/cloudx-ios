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
    
    init(appKey: String,
         hashedUserId: String,
         bannerAdUnitId: String,
         mrecAdUnitId: String,
         interstitialAdUnitId: String,
         nativeAdUnitId: String,
         nativeBannerAdUnitId: String,
         rewardedAdUnitId: String) {
        
        self.appKey = appKey
        self.hashedUserId = hashedUserId
        self.bannerAdUnitId = bannerAdUnitId
        self.mrecAdUnitId = mrecAdUnitId
        self.interstitialAdUnitId = interstitialAdUnitId
        self.nativeAdUnitId = nativeAdUnitId
        self.nativeBannerAdUnitId = nativeBannerAdUnitId
        self.rewardedAdUnitId = rewardedAdUnitId
    }
}

class CLXDemoConfigManager {
    static let sharedManager = CLXDemoConfigManager()
    
    // Production configuration for remote pods demo
    let currentConfig: CLXDemoConfig
    
    private init() {
        // QA can pin a specific app key / ad unit id at launch via
        // `simctl launch ... -DemoApp.<Key> <value>` (NSArgumentDomain). Unset ->
        // the hardcoded defaults. Read once; nothing is written, so overrides
        // never persist across launches.
        let defaults = UserDefaults.standard
        func overrideOrDefault(_ key: String, _ fallback: String) -> String {
            let value = defaults.string(forKey: key) ?? ""
            return value.isEmpty ? fallback : value
        }
        NSLog("%@", "📱 [DemoApp] launch overrides: appKey=\(defaults.string(forKey: "DemoApp.AppKey") ?? "(none)") banner=\(defaults.string(forKey: "DemoApp.BannerAdUnitId") ?? "(none)") mrec=\(defaults.string(forKey: "DemoApp.MrecAdUnitId") ?? "(none)") interstitial=\(defaults.string(forKey: "DemoApp.InterstitialAdUnitId") ?? "(none)") rewarded=\(defaults.string(forKey: "DemoApp.RewardedAdUnitId") ?? "(none)")")

        // Production Configuration (shared with ObjC demo - bundle: cloudx.CloudXObjCRemotePods)
        // Both demos share the same SSP-side appKey, ad units, and bundle ID — they're the
        // same logical app, two language implementations. Only one can be installed per
        // simulator at a time (uninstall the other before installing).
        self.currentConfig = CLXDemoConfig(
            appKey: overrideOrDefault("DemoApp.AppKey", "ihtOXvp3X9JlMQ5p0_RYL"),
            hashedUserId: "test-user-123",
            bannerAdUnitId: overrideOrDefault("DemoApp.BannerAdUnitId", "LyPxKhBFiUCd1xMLYQhGc"),
            mrecAdUnitId: overrideOrDefault("DemoApp.MrecAdUnitId", "EWaeXDSmKYbs220gM5hTv"),
            interstitialAdUnitId: overrideOrDefault("DemoApp.InterstitialAdUnitId", "txZ7NmISq-MsuPH0ULKbD"),
            nativeAdUnitId: "Q33RbPmBH-wix45Mu6--Z",
            nativeBannerAdUnitId: "-2_Lw2b4QTlu7x6tKZ6Ww",
            rewardedAdUnitId: overrideOrDefault("DemoApp.RewardedAdUnitId", "um9Ek08ScJBWuzSMTyW3b")
        )
    }
}
