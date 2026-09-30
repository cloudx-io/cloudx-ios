import CloudXCore
import UIKit

/** CloudX's leg of the First Look interstitial flow. */
final class CloudXFirstLookSource: NSObject, FirstLookInterstitialSource {

    private weak var viewController: UIViewController?
    private let ad: CLXInterstitial

    var onEvent: ((FirstLookEvent) -> Void)?

    /** Returns nil when the SDK cannot create the interstitial, for example when it is not initialized. */
    init?(viewController: UIViewController, adUnitId: String) {
        guard let ad = CloudXCore.shared.createInterstitial(adUnitId: adUnitId) else { return nil }
        self.viewController = viewController
        self.ad = ad
        super.init()
        ad.delegate = self
        ad.revenueDelegate = self
    }

    var isReady: Bool { ad.isReady }

    func load() {
        ad.load()
    }

    func show() {
        guard let viewController = viewController else {
            onEvent?(.showFailed(.cloudX, message: "View controller unavailable"))
            return
        }
        ad.show(from: viewController)
    }

    func dispose() {
        viewController = nil
        ad.delegate = nil
        ad.revenueDelegate = nil
        ad.destroy()
        onEvent = nil
    }
}

extension CloudXFirstLookSource: CLXInterstitialDelegate, CLXAdRevenueDelegate {

    func didLoad(_ ad: CLXAd) {
        onEvent?(.loaded(.cloudX))
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        DemoAppLogger.sharedInstance.logMessage("CloudX interstitial failed to load: \(error.localizedDescription); trying AdMob")
        onEvent?(.loadFailed(.cloudX, message: error.localizedDescription))
    }

    func didDisplay(_ ad: CLXAd) {
        onEvent?(.shown(.cloudX))
    }

    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        onEvent?(.showFailed(.cloudX, message: error.localizedDescription))
    }

    func didHide(_ ad: CLXAd) {
        onEvent?(.closed(.cloudX))
    }

    func didClick(_ ad: CLXAd) {
        onEvent?(.clicked(.cloudX))
    }

    func didPayRevenue(for ad: CLXAd) {
        let revenue = ad.revenue.map { String(format: "$%.6f", $0.doubleValue) } ?? "(null)"
        DemoAppLogger.sharedInstance.logMessage("CloudX interstitial revenue: \(revenue)")
    }
}
