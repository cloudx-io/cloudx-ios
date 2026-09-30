import CloudXCore
import UIKit

/**
 * Demo host for the Trusted Arbiter interstitial. `DemoSdkStartup` brings up both SDKs; this screen
 * builds an `ArbiterInterstitialController`, turns its events into status lines and retries with a
 * capped backoff when neither platform fills or a show fails. Every load, show, arbiter and revenue
 * call lives in the controller.
 */
final class ArbiterViewController: UIViewController {

    private let initializationStatusLabel = DemoFlowLayout.makeStatusLabel()
    private let roundStatusLabel = DemoFlowLayout.makeStatusLabel()
    private let interstitialStatusLabel = DemoFlowLayout.makeStatusLabel()
    private let revenueStatusLabel = DemoFlowLayout.makeStatusLabel()
    private let logTextView = LiveLogTextView(accessibilityLabel: "Arbiter/TPA logs")
    private let showButton = DemoFlowLayout.makeShowButton()
    private let retry = RetryScheduler()

    private var startup: DemoSdkStartup?
    private var controller: ArbiterInterstitialController?

    deinit {
        controller?.dispose()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Arbiter/TPA"
        view.backgroundColor = .systemBackground
        roundStatusLabel.text = "Arbiter: not run yet"
        interstitialStatusLabel.text = "Waiting for initialization"
        revenueStatusLabel.text = "Revenue -> CloudX: no AdMob paid event yet"
        showButton.addTarget(self, action: #selector(showInterstitial), for: .touchUpInside)
        DemoFlowLayout.install(
            [initializationStatusLabel, roundStatusLabel, interstitialStatusLabel, revenueStatusLabel, logTextView, showButton],
            in: view
        )

        let startup = DemoSdkStartup(
            onStatus: { [weak self] status in self?.initializationStatusLabel.text = status },
            onCloudXSettled: { [weak self] cloudXAvailable in self?.createController(cloudXAvailable: cloudXAvailable) }
        )
        self.startup = startup
        startup.start()
    }

    private func createController(cloudXAvailable: Bool) {
        guard controller == nil else { return }
        let newController = ArbiterInterstitialController(
            viewController: self,
            cloudXAdUnitId: CLXDemoConfigManager.sharedManager.currentConfig.arbiterInterstitialAdUnitId,
            adMobAdUnitId: AdMobDemoConfig.interstitialAdUnitId,
            cloudXAvailable: cloudXAvailable,
            onEvent: { [weak self] event in self?.onArbiterEvent(event) }
        )
        controller = newController
        interstitialStatusLabel.text = "Loading CloudX and AdMob…"
        showButton.isEnabled = true
        newController.load()
    }

    @objc private func showInterstitial() {
        guard let controller = controller else { return }
        if let platform = controller.show() {
            DemoAppLogger.sharedInstance.logMessage("Requested interstitial (\(platform.name))")
        } else if controller.isShowing {
            return
        } else if controller.isBusy {
            // A load or a round is still running, and its result will update the status lines.
            roundStatusLabel.text = "Arbiter: round in progress"
        } else if retry.isPending {
            // A tap must not skip the backoff of a retry that is already scheduled.
            interstitialStatusLabel.text = "No winner prepared; waiting for the scheduled retry"
        } else {
            /*
             * A real app carries on without an ad here. The demo reloads so that the next tap has a
             * winner to show.
             */
            interstitialStatusLabel.text = "No winner prepared; reloading"
            controller.load()
        }
    }

    private func onArbiterEvent(_ event: ArbiterEvent) {
        switch event {
        case .loaded(let platform):
            retry.reset()
            interstitialStatusLabel.text = "Loaded (\(platform.name))"
            DemoAppLogger.sharedInstance.logMessage("Interstitial loaded (\(platform.name))")
        case .loadFailed(let platform, let message):
            interstitialStatusLabel.text = "Load failed (\(platform.name)): \(message)"
            DemoAppLogger.sharedInstance.logMessage("Interstitial failed to load (\(platform.name)): \(message)")
        case .arbiterCompleted(let platform, let bidCount):
            let bids = bidCount == 1 ? "1 bid" : "\(bidCount) bids"
            roundStatusLabel.text = platform.name == CLXArbiterPlatform.none.name
                ? "Arbiter: no winner (\(bids))"
                : "Arbiter: \(platform.name) (\(bids))"
        case .noCandidates:
            roundStatusLabel.text = "Arbiter: no candidates, nothing to arbitrate"
            scheduleRetry(message: "Neither platform filled")
        case .shown(let platform):
            interstitialStatusLabel.text = "Showing (\(platform.name))"
            DemoAppLogger.sharedInstance.logMessage("Interstitial shown (\(platform.name))")
        case .showFailed(let platform, let message):
            scheduleRetry(message: "Show failed (\(platform.name)): \(message)")
        case .closed(let platform):
            interstitialStatusLabel.text = "Closed (\(platform.name)); loading the next round"
            DemoAppLogger.sharedInstance.logMessage("Interstitial closed (\(platform.name))")
            controller?.load()
        case .clicked(let platform):
            DemoAppLogger.sharedInstance.logMessage("Interstitial clicked (\(platform.name))")
        case .revenueReported(let revenue, let currencyCode, let accepted):
            revenueStatusLabel.text = "Revenue -> CloudX: \(String(format: "%.6f", revenue)) \(currencyCode) (accepted=\(accepted))"
        }
    }

    private func scheduleRetry(message: String) {
        let seconds = retry.schedule { [weak self] in self?.controller?.load() }
        interstitialStatusLabel.text = "\(message)\nRetrying in \(seconds)s…"
        DemoAppLogger.sharedInstance.logMessage("\(message); retrying in \(seconds)s")
    }
}
