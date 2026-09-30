import UIKit

/**
 * Demo host for a CloudX-first interstitial with a lazy AdMob fallback. `DemoSdkStartup` brings up
 * both SDKs; once CloudX has answered (or after 15 s without an answer) this screen builds a
 * `FirstLookInterstitialController`, retries failed loads and shows with a capped backoff and
 * reports each step in the status lines.
 */
final class FirstLookViewController: UIViewController {

    private let initializationStatusLabel = DemoFlowLayout.makeStatusLabel()
    private let interstitialStatusLabel = DemoFlowLayout.makeStatusLabel()
    private let logTextView = LiveLogTextView(accessibilityLabel: "First Look logs")
    private let showButton = DemoFlowLayout.makeShowButton()
    private let retry = RetryScheduler()

    private var startup: DemoSdkStartup?
    private var controller: FirstLookInterstitialController?

    deinit {
        controller?.dispose()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "First Look"
        view.backgroundColor = .systemBackground
        interstitialStatusLabel.text = "Waiting for initialization"
        showButton.addTarget(self, action: #selector(showInterstitial), for: .touchUpInside)
        DemoFlowLayout.install([initializationStatusLabel, interstitialStatusLabel, logTextView, showButton], in: view)

        let startup = DemoSdkStartup(
            onStatus: { [weak self] status in self?.initializationStatusLabel.text = status },
            onCloudXSettled: { [weak self] cloudXAvailable in self?.createController(cloudXAvailable: cloudXAvailable) }
        )
        self.startup = startup
        startup.start()
    }

    private func createController(cloudXAvailable: Bool) {
        guard controller == nil else { return }

        var cloudXSource: FirstLookInterstitialSource?
        if cloudXAvailable {
            let adUnitId = CLXDemoConfigManager.sharedManager.currentConfig.interstitialAdUnitId
            cloudXSource = CloudXFirstLookSource(viewController: self, adUnitId: adUnitId)
            if cloudXSource == nil {
                DemoAppLogger.sharedInstance.logMessage("CloudX interstitial unavailable; AdMob only")
            }
        }
        let newController = FirstLookInterstitialController(
            cloudX: cloudXSource,
            adMob: AdMobFirstLookSource(viewController: self, adUnitId: AdMobDemoConfig.interstitialAdUnitId),
            onEvent: { [weak self] event in self?.onInterstitialEvent(event) }
        )
        controller = newController
        interstitialStatusLabel.text = "Loading interstitial…"
        showButton.isEnabled = true
        newController.load()
    }

    @objc private func showInterstitial() {
        if let source = controller?.show() {
            DemoAppLogger.sharedInstance.logMessage("Requested interstitial (\(source))")
        } else if retry.isPending {
            // A tap must not skip the backoff of a retry that is already scheduled.
            interstitialStatusLabel.text = "No ad ready; waiting for the scheduled retry"
        } else {
            interstitialStatusLabel.text = "No ad ready; reloading"
            controller?.load()
        }
    }

    private func onInterstitialEvent(_ event: FirstLookEvent) {
        switch event {
        case .loaded(let source):
            retry.reset()
            interstitialStatusLabel.text = "Loaded (\(source))"
            DemoAppLogger.sharedInstance.logMessage("Interstitial loaded (\(source))")
        case .loadFailed(let source, let message):
            scheduleRetry(message: "Load failed (\(source)): \(message)")
        case .shown(let source):
            interstitialStatusLabel.text = "Showing (\(source))"
            DemoAppLogger.sharedInstance.logMessage("Interstitial shown (\(source))")
        case .showFailed(let source, let message):
            scheduleRetry(message: "Show failed (\(source)): \(message)")
        case .closed(let source):
            interstitialStatusLabel.text = "Closed (\(source)); loading next ad"
            DemoAppLogger.sharedInstance.logMessage("Interstitial closed (\(source))")
            controller?.load()
        case .clicked(let source):
            DemoAppLogger.sharedInstance.logMessage("Interstitial clicked (\(source))")
        }
    }

    private func scheduleRetry(message: String) {
        let seconds = retry.schedule { [weak self] in self?.controller?.load() }
        interstitialStatusLabel.text = "\(message)\nRetrying in \(seconds)s…"
        DemoAppLogger.sharedInstance.logMessage("\(message); retrying in \(seconds)s")
    }
}
