import CloudXCore
import GoogleMobileAds
import QuartzCore
import UIKit

/** Events from the arbiter flow. Each one names the platform it came from. */
enum ArbiterEvent {
    case loaded(CLXArbiterPlatform)
    case loadFailed(CLXArbiterPlatform, message: String)

    /** A round finished. The platform is `CLXArbiterPlatform.none` when no winner was selected. */
    case arbiterCompleted(CLXArbiterPlatform, bidCount: Int)

    /** Both platforms settled without a fill, so there is nothing to arbitrate. */
    case noCandidates

    case shown(CLXArbiterPlatform)
    case showFailed(CLXArbiterPlatform, message: String)
    case closed(CLXArbiterPlatform)
    case clicked(CLXArbiterPlatform)
    case revenueReported(revenue: Double, currencyCode: String, accepted: Bool)
}

/**
 * Trusted Arbiter for interstitials. CloudX and AdMob load in parallel, the ones that fill become
 * bids, and `CloudXCore.shared.arbiter(with:completion:)` picks the platform to show.
 *
 * The arbiter runs as soon as both platforms have settled (loaded or failed) and the winner is
 * stored, so `show()` makes no arbiter or network call. It returns nil when no winner is prepared,
 * and the app carries on without an ad. Call `load()` after an ad closes to start the next round;
 * it reloads only the platform that has no fill.
 *
 * AdMob bids carry no price. CloudX prices them from the revenue this controller forwards after
 * every AdMob impression through `CloudXCore.shared.reportRevenueData(_:)`, so that forwarding is a
 * required part of the integration, not analytics.
 *
 * Pass false for `cloudXAvailable` when CloudX initialization failed or did not answer. AdMob is
 * then the only candidate and wins each round here, without a call into an SDK that is not
 * initialized. Both SDKs report on the main queue, so `onEvent` is called there too.
 */
final class ArbiterInterstitialController: NSObject {

    private static let adFormat = "interstitial"
    private static let adMobAdTimeToLive: CFTimeInterval = 60 * 60

    private weak var viewController: UIViewController?
    private let adMobAdUnitId: String
    private let onEvent: (ArbiterEvent) -> Void

    /*
     * One CloudX ad object for the controller's lifetime: a load after the ad closes runs a new
     * auction on it. Nil when CloudX is not available.
     */
    private let cloudXInterstitial: CLXInterstitial?
    private var loadedCloudXAd: CLXAd?
    private var cloudXLoading = false
    private var cloudXSettled: Bool

    private var adMobAd: InterstitialAd?
    /*
     * An InterstitialAd is single-use, so a shown ad moves here. It stays alive until the next show
     * because AdMob can deliver the paid event after the ad was dismissed, and that revenue is what
     * prices the next AdMob bid.
     */
    private var presentedAdMobAd: InterstitialAd?
    private var adMobLoadedAt: CFTimeInterval = 0
    private var adMobLoading = false
    private var adMobSettled = false

    private var nextWinner: CLXArbiterPlatform?
    private var arbiterInFlight = false
    private var showing = false
    private var disposed = false

    init(
        viewController: UIViewController,
        cloudXAdUnitId: String,
        adMobAdUnitId: String,
        cloudXAvailable: Bool,
        onEvent: @escaping (ArbiterEvent) -> Void
    ) {
        self.viewController = viewController
        self.adMobAdUnitId = adMobAdUnitId
        self.onEvent = onEvent
        cloudXInterstitial = cloudXAvailable ? CloudXCore.shared.createInterstitial(adUnitId: cloudXAdUnitId) : nil
        cloudXSettled = cloudXInterstitial == nil
        super.init()
        if cloudXAvailable && cloudXInterstitial == nil {
            DemoAppLogger.sharedInstance.logMessage("CloudX interstitial unavailable; AdMob only")
        }
        cloudXInterstitial?.delegate = self
    }

    /** True from a show call until that ad closes or fails to show. */
    var isShowing: Bool { showing }

    /** True while a load or an arbiter round is in flight, so another event is still coming. */
    var isBusy: Bool { cloudXLoading || adMobLoading || arbiterInFlight }

    private var cloudXReady: Bool {
        loadedCloudXAd != nil && cloudXInterstitial?.isReady == true
    }

    /* A loaded AdMob interstitial can be shown once and expires after one hour. */
    private var adMobReady: Bool {
        if adMobAd != nil && CACurrentMediaTime() - adMobLoadedAt >= Self.adMobAdTimeToLive {
            adMobAd = nil
        }
        return adMobAd != nil
    }

    /**
     * Loads each platform that holds no fill, then runs a new round once both have settled. Does
     * nothing while a round is in flight or an ad is showing.
     */
    func load() {
        if disposed || arbiterInFlight || showing { return }

        /*
         * Both settled flags are cleared before either load starts: CloudX can report a failure
         * inside its own load call, and the round must not run then on the other platform's result
         * from the previous round.
         */
        let loadsCloudX = cloudXInterstitial != nil && !cloudXReady && !cloudXLoading
        let loadsAdMob = !adMobReady && !adMobLoading
        if loadsCloudX {
            loadedCloudXAd = nil
            cloudXSettled = false
            cloudXLoading = true
        }
        if loadsAdMob {
            adMobSettled = false
            adMobLoading = true
        }
        if loadsCloudX { cloudXInterstitial?.load() }
        if loadsAdMob { loadAdMob() }

        /*
         * Both platforms may still hold their fills with no winner stored, after a round with no
         * winner or a winner that went stale. Nothing loads then, so the round runs from here.
         */
        if !loadsCloudX && !loadsAdMob && nextWinner == nil { maybePrepareWinner() }
    }

    /**
     * Shows the stored winner and returns its platform. Returns nil when there is nothing to show:
     * no winner is prepared, an ad is already showing (check `isShowing`), or the winner's ad
     * expired, in which case `load()` reloads that platform and runs a new round.
     */
    func show() -> CLXArbiterPlatform? {
        guard !disposed, !showing, let host = viewController, let winner = nextWinner else { return nil }
        nextWinner = nil

        switch winner.name {
        case CLXArbiterPlatform.cloudX.name:
            guard let cloudX = cloudXInterstitial, cloudXReady else {
                loadedCloudXAd = nil
                return nil
            }
            showing = true
            cloudX.show(from: host)
        case CLXArbiterPlatform.adMob.name:
            guard adMobReady, let ad = adMobAd else { return nil }
            adMobAd = nil
            presentedAdMobAd = ad
            showing = true
            ad.present(from: host)
        default:
            return nil
        }
        return winner
    }

    func dispose() {
        if disposed { return }
        disposed = true
        viewController = nil
        cloudXInterstitial?.delegate = nil
        cloudXInterstitial?.destroy()
        for ad in [adMobAd, presentedAdMobAd].compactMap({ $0 }) {
            ad.fullScreenContentDelegate = nil
            ad.paidEventHandler = nil
        }
        adMobAd = nil
        presentedAdMobAd = nil
    }

    /*
     * Runs one round once both platforms have settled and stores the winner. The SDK owns the
     * timeout and the fallback, and always completes: a single bid wins without a service call, and
     * several bids go to the arbiter service or, when it is unavailable, to the highest locally
     * comparable price. So nothing here times the call out or compares prices.
     */
    private func maybePrepareWinner() {
        if disposed || showing || arbiterInFlight || !cloudXSettled || !adMobSettled { return }

        var bids: [CLXArbiterBid] = []
        if let cloudXAd = loadedCloudXAd, cloudXReady {
            bids.append(CLXArbiterBid.cloudX(ad: cloudXAd))
        }
        if adMobReady, let ad = adMobAd {
            bids.append(CLXArbiterBid.adMob(
                adUnitId: adMobAdUnitId,
                networkName: ad.responseInfo.loadedAdNetworkResponseInfo?.adSourceName ?? "admob",
                manualRevenuePerImpressionUSD: nil,
                extras: nil
            ))
        }
        if bids.isEmpty {
            onEvent(.noCandidates)
            return
        }

        if cloudXInterstitial == nil {
            DemoAppLogger.sharedInstance.logMessage("CloudX is not available, so the AdMob bid wins without an arbiter call")
            storeWinner(CLXArbiterPlatform.adMob, bidCount: bids.count)
            return
        }

        arbiterInFlight = true
        let bidCount = bids.count
        DemoAppLogger.sharedInstance.logMessage("Running the arbiter with \(bidCount) bid(s)")
        let configuration = CLXArbiterConfiguration.configuration(bids: bids, builderBlock: nil)
        CloudXCore.shared.arbiter(with: configuration) { [weak self] result in
            guard let self = self else { return }
            self.arbiterInFlight = false
            if self.disposed { return }
            DemoAppLogger.sharedInstance.logMessage(
                "Arbiter result: platform=\(result.platform.name) platformName=\(result.platformName) "
                    + "id=\(result.identifier) bidId=\(result.bidId ?? "-") bids=\(bidCount)"
            )
            self.storeWinner(result.platform, bidCount: bidCount)
        }
    }

    /* NONE is not stored: a stored NONE would leave both fills held and no round left to run. */
    private func storeWinner(_ platform: CLXArbiterPlatform, bidCount: Int) {
        nextWinner = platform.name == CLXArbiterPlatform.none.name ? nil : platform
        onEvent(.arbiterCompleted(platform, bidCount: bidCount))
    }

    private func loadAdMob() {
        InterstitialAd.load(with: adMobAdUnitId, request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            self.adMobLoading = false
            if self.disposed { return }
            guard let ad = ad else {
                self.adMobSettled = true
                self.onEvent(.loadFailed(CLXArbiterPlatform.adMob, message: error?.localizedDescription ?? "No ad returned"))
                self.maybePrepareWinner()
                return
            }
            ad.fullScreenContentDelegate = self
            ad.paidEventHandler = { [weak self, weak ad] adValue in
                guard let self = self, let ad = ad else { return }
                self.reportAdMobPaidEvent(ad, adValue: adValue)
            }
            self.adMobAd = ad
            self.adMobLoadedAt = CACurrentMediaTime()
            self.adMobSettled = true
            self.onEvent(.loaded(CLXArbiterPlatform.adMob))
            self.maybePrepareWinner()
        }
    }

    /*
     * Required: this is how CloudX learns what an AdMob bid is worth. The iOS Google Mobile Ads SDK
     * reports the value in currency units, not micros, so it is passed through unchanged.
     */
    private func reportAdMobPaidEvent(_ ad: InterstitialAd, adValue: AdValue) {
        let servedBy = ad.responseInfo.loadedAdNetworkResponseInfo
        let revenue = adValue.value.doubleValue
        let data = CLXRevenueData.revenueData(platform: .adMob, revenue: revenue, adFormat: Self.adFormat) { builder in
            builder.currencyCode = adValue.currencyCode
            builder.precision = Self.revenuePrecision(from: adValue.precision)
            builder.networkName = servedBy?.adSourceName
            builder.adUnitId = self.adMobAdUnitId
            builder.thirdPartyAdPlacementId = servedBy?.adSourceInstanceName
        }
        let accepted = CloudXCore.shared.reportRevenueData(data)
        DemoAppLogger.sharedInstance.logMessage("reportRevenueData(\(adValue.value) \(adValue.currencyCode)) returned \(accepted)")
        if !disposed {
            onEvent(.revenueReported(revenue: revenue, currencyCode: adValue.currencyCode, accepted: accepted))
        }
    }

    private static func revenuePrecision(from precision: AdValuePrecision) -> CLXRevenuePrecision {
        switch precision {
        case .precise: return .exact
        case .estimated: return .estimated
        case .publisherProvided: return .publisherDefined
        default: return .undefined
        }
    }
}

extension ArbiterInterstitialController: CLXInterstitialDelegate {

    func didLoad(_ ad: CLXAd) {
        if disposed { return }
        cloudXLoading = false
        loadedCloudXAd = ad
        cloudXSettled = true
        let revenue = ad.revenue.map { String(format: "%.6f", $0.doubleValue) } ?? "(null)"
        DemoAppLogger.sharedInstance.logMessage("CloudX bid from \(ad.networkName ?? "(null)"), revenue \(revenue)")
        onEvent(.loaded(CLXArbiterPlatform.cloudX))
        maybePrepareWinner()
    }

    func didFailToLoadAd(_ adUnitId: String, error: CLXError) {
        if disposed { return }
        cloudXLoading = false
        loadedCloudXAd = nil
        cloudXSettled = true
        onEvent(.loadFailed(CLXArbiterPlatform.cloudX, message: error.localizedDescription))
        maybePrepareWinner()
    }

    func didDisplay(_ ad: CLXAd) {
        if !disposed { onEvent(.shown(CLXArbiterPlatform.cloudX)) }
    }

    func didFailToDisplay(_ ad: CLXAd, error: CLXError) {
        if disposed { return }
        loadedCloudXAd = nil
        showing = false
        onEvent(.showFailed(CLXArbiterPlatform.cloudX, message: error.localizedDescription))
    }

    func didHide(_ ad: CLXAd) {
        if disposed { return }
        loadedCloudXAd = nil
        showing = false
        onEvent(.closed(CLXArbiterPlatform.cloudX))
    }

    func didClick(_ ad: CLXAd) {
        if !disposed { onEvent(.clicked(CLXArbiterPlatform.cloudX)) }
    }
}

extension ArbiterInterstitialController: FullScreenContentDelegate {

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        if !disposed { onEvent(.shown(CLXArbiterPlatform.adMob)) }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if disposed { return }
        showing = false
        onEvent(.closed(CLXArbiterPlatform.adMob))
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if disposed { return }
        showing = false
        onEvent(.showFailed(CLXArbiterPlatform.adMob, message: error.localizedDescription))
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        if !disposed { onEvent(.clicked(CLXArbiterPlatform.adMob)) }
    }
}
