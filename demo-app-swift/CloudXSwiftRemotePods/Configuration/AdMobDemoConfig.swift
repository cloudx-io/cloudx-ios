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

    /**
     * A manual price for every Arbiter/TPA AdMob bid, in USD per impression, or nil for none.
     * `-DemoApp.AdMobManualRevenuePerImpressionUSD <usd>` sets it for one launch so QA can run a round
     * that compares prices: Google's test unit reports 0, so without it the AdMob bid never has a
     * price. A testing aid only; leave it unset in a production app.
     */
    static let manualRevenuePerImpressionUSD: NSNumber? = {
        guard let text = UserDefaults.standard.string(forKey: "DemoApp.AdMobManualRevenuePerImpressionUSD"),
              let value = Double(text), value.isFinite, value >= 0 else { return nil }
        return NSNumber(value: value)
    }()
}
