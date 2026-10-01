import CloudXCore
import GoogleMobileAds
import UIKit

/**
 * Demo host for a CloudX-first interstitial with a lazy AdMob fallback. It starts Google Mobile
 * Ads, requests App Tracking Transparency and then initializes CloudX, builds a
 * `FirstLookInterstitialController` once CloudX has answered (or after 15 s without an answer),
 * retries failed loads and shows with a capped backoff and reports each step in the status lines.
 */
final class FirstLookViewController: UIViewController {

    /*
     * Google's test interstitial for iOS. Replace it, and the GADApplicationIdentifier in
     * Info.plist, with your own IDs before using this flow in a production app.
     */
    private static let adMobInterstitialAdUnitId = "ca-app-pub-3940256099942544/4411468910"
    private static let initializationTimeout: TimeInterval = 15
    private static let retryBaseDelay: TimeInterval = 2
    private static let retryMaxDelay: TimeInterval = 60
    private static let retryMaxShift = 5
    // Same bound as DemoAppLogger, so a screen left open through the retry loop cannot grow without limit.
    private static let logLineLimit = 500

    private let initializationStatusLabel = UILabel()
    private let interstitialStatusLabel = UILabel()
    private let logTextView = UITextView()
    private let showButton = UIButton(type: .system)

    private var cloudXStatus = "CloudX: Initializing"
    private var adMobStatus = "AdMob: Initializing"
    private var controller: FirstLookInterstitialController?
    private var initializationTimeoutWork: DispatchWorkItem?
    private var retryWork: DispatchWorkItem?
    private var retryCount = 0
    private var logLines: [String] = []
    private var logObserver: NSObjectProtocol?

    deinit {
        initializationTimeoutWork?.cancel()
        retryWork?.cancel()
        controller?.dispose()
        if let logObserver = logObserver {
            NotificationCenter.default.removeObserver(logObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "First Look"
        view.backgroundColor = .systemBackground
        setupViews()
        publishInitializationStatus()
        interstitialStatusLabel.text = "Waiting for initialization"
        observeLogs()

        initializeAdMob()
        AppTrackingPermission.request { [weak self] in
            self?.initializeCloudX()
        }
    }

    private func setupViews() {
        for label in [initializationStatusLabel, interstitialStatusLabel] {
            label.font = .systemFont(ofSize: 15)
            label.numberOfLines = 0
        }

        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.layer.cornerRadius = 8
        logTextView.accessibilityLabel = "First Look logs"

        showButton.setTitle("Show Interstitial", for: .normal)
        showButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        showButton.isEnabled = false
        showButton.addTarget(self, action: #selector(showInterstitial), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [initializationStatusLabel, interstitialStatusLabel, logTextView, showButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            showButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    /**
     * Shows every demo log line as it is written, so the screen shows what the sources report.
     * Keeps the last `logLineLimit` lines and re-renders from that buffer.
     */
    private func observeLogs() {
        logObserver = NotificationCenter.default.addObserver(
            forName: DemoAppLogger.didAppendEntry,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let entry = notification.userInfo?[DemoAppLogger.entryUserInfoKey] as? DemoAppLogEntry else { return }
            self.logLines.append("\(entry.formattedTimestamp) \(entry.message)")
            if self.logLines.count > Self.logLineLimit {
                self.logLines.removeFirst(self.logLines.count - Self.logLineLimit)
            }
            self.logTextView.text = self.logLines.joined(separator: "\n")
            let end = NSRange(location: self.logTextView.text.utf16.count, length: 0)
            self.logTextView.scrollRangeToVisible(end)
        }
    }

    /*
     * Loads do not wait for this. Google asks apps to wait for the completion handler only when they
     * use AdMob mediation, which this fallback does not.
     */
    private func initializeAdMob() {
        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.adMobStatus = "AdMob: Ready"
                self.publishInitializationStatus()
            }
        }
    }

    /** Waits up to 15 s for the CloudX answer, then continues with AdMob only. */
    private func initializeCloudX() {
        let config = CLXDemoConfigManager.sharedManager.currentConfig
        if !config.hashedUserId.isEmpty {
            CloudXCore.shared.setHashedUserID(config.hashedUserId)
        }
        DemoAppLogger.sharedInstance.logMessage("Initializing CloudX SDK")

        let timeoutWork = DispatchWorkItem { [weak self] in
            guard let self = self, self.controller == nil else { return }
            self.cloudXStatus = "CloudX: No response, AdMob only"
            self.publishInitializationStatus()
            self.createController(cloudXAvailable: false)
        }
        initializationTimeoutWork = timeoutWork
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.initializationTimeout, execute: timeoutWork)

        let initConfig = CLXInitializationConfiguration.configuration(appKey: config.appKey)
        CloudXCore.shared.initialize(with: initConfig) { [weak self] sdkConfig, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if sdkConfig != nil {
                    DemoAppLogger.sharedInstance.logMessage("CloudX SDK initialized")
                    self.cloudXStatus = self.controller == nil
                        ? "CloudX: Initialized"
                        : "CloudX: Initialized late, AdMob only"
                    self.publishInitializationStatus()
                    self.createController(cloudXAvailable: true)
                } else {
                    let message = error?.localizedDescription ?? "Unknown error"
                    DemoAppLogger.sharedInstance.logMessage("CloudX SDK initialization failed: \(message)")
                    self.cloudXStatus = "CloudX: Failed (\(message))"
                    self.publishInitializationStatus()
                    self.createController(cloudXAvailable: false)
                }
            }
        }
    }

    private func createController(cloudXAvailable: Bool) {
        guard controller == nil else { return }
        initializationTimeoutWork?.cancel()
        initializationTimeoutWork = nil

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
            adMob: AdMobFirstLookSource(viewController: self, adUnitId: Self.adMobInterstitialAdUnitId),
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
        } else if retryWork != nil {
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
            retryWork?.cancel()
            retryWork = nil
            retryCount = 0
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

    /*
     * Retry policy after a load or show failure: 2 s, 4 s, 8 s and so on up to 60 s, reset by the
     * next successful load. A fixed short delay would turn sustained no-fill into a tight request
     * loop against the fallback network.
     */
    private func scheduleRetry(message: String) {
        let delay = min(Self.retryBaseDelay * TimeInterval(1 << retryCount), Self.retryMaxDelay)
        retryCount = min(retryCount + 1, Self.retryMaxShift)
        let seconds = Int(delay)
        interstitialStatusLabel.text = "\(message)\nRetrying in \(seconds)s…"
        DemoAppLogger.sharedInstance.logMessage("\(message); retrying in \(seconds)s")
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.retryWork = nil
            self.controller?.load()
        }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func publishInitializationStatus() {
        initializationStatusLabel.text = "\(cloudXStatus) | \(adMobStatus)"
    }
}
