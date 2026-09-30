import Foundation

/**
 * The AdMob IDs the First Look and Arbiter/TPA flows load. They are Google's test IDs: replace them,
 * and the GADApplicationIdentifier in Info.plist, with your own IDs before using either flow in a
 * production app.
 */
enum AdMobDemoConfig {

    /** Google's test interstitial for iOS. `-DemoApp.AdMobInterstitialAdUnitId <id>` overrides it for one launch. */
    static let interstitialAdUnitId: String = {
        let override = UserDefaults.standard.string(forKey: "DemoApp.AdMobInterstitialAdUnitId") ?? ""
        return override.isEmpty ? "ca-app-pub-3940256099942544/4411468910" : override
    }()
}
