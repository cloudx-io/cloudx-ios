import GoogleMobileAds
import QuartzCore
import UIKit

/** The lazy AdMob fallback. A loaded ad can be shown once and expires after one hour. */
final class AdMobFirstLookSource: NSObject, FirstLookInterstitialSource {

    private static let adTimeToLive: CFTimeInterval = 60 * 60

    private weak var viewController: UIViewController?
    private let adUnitId: String
    private var ad: InterstitialAd?
    private var loadedAt: CFTimeInterval = 0
    private var loading = false
    private var disposed = false

    var onEvent: ((FirstLookEvent) -> Void)?

    init(viewController: UIViewController, adUnitId: String) {
        self.viewController = viewController
        self.adUnitId = adUnitId
    }

    var isReady: Bool {
        if disposed { return false }
        if ad != nil && CACurrentMediaTime() - loadedAt >= Self.adTimeToLive {
            ad = nil
        }
        return ad != nil
    }

    func load() {
        if disposed || loading || isReady { return }
        loading = true
        DemoAppLogger.sharedInstance.logMessage("Loading AdMob interstitial fallback")
        InterstitialAd.load(with: adUnitId, request: Request()) { [weak self] loadedAd, error in
            guard let self = self else { return }
            self.loading = false
            if self.disposed { return }
            if let error = error {
                self.onEvent?(.loadFailed(.adMob, message: error.localizedDescription))
                return
            }
            guard let loadedAd = loadedAd else {
                self.onEvent?(.loadFailed(.adMob, message: "No ad returned"))
                return
            }
            self.ad = loadedAd
            self.loadedAt = CACurrentMediaTime()
            loadedAd.fullScreenContentDelegate = self
            self.onEvent?(.loaded(.adMob))
        }
    }

    func show() {
        guard isReady, let loadedAd = ad, let viewController = viewController else {
            onEvent?(.showFailed(.adMob, message: "Ad is no longer ready"))
            return
        }
        ad = nil
        loadedAd.present(from: viewController)
    }

    func dispose() {
        disposed = true
        viewController = nil
        ad?.fullScreenContentDelegate = nil
        ad = nil
        onEvent = nil
    }
}

extension AdMobFirstLookSource: FullScreenContentDelegate {

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        if !disposed { onEvent?(.shown(.adMob)) }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if !disposed { onEvent?(.closed(.adMob)) }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if !disposed { onEvent?(.showFailed(.adMob, message: error.localizedDescription)) }
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        if !disposed { onEvent?(.clicked(.adMob)) }
    }
}
