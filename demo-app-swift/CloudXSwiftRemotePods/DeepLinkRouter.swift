import UIKit
import AppTrackingTransparency

/// Routes `cloudx-demo://` deep link URLs to the appropriate ad format tab and triggers load/show actions.
///
/// Used by automated test runners to exercise all ad formats via `xcrun simctl openurl`.
///
/// Supported routes:
/// - `cloudx-demo://init[?env=production|staging|dev]`
/// - `cloudx-demo://test?format=<FORMAT>[&action=load|show]`
/// - `cloudx-demo://test-all`
enum DeepLinkRouter {

    private static let scheme = "cloudx-demo"

    /// Checks process launch arguments for test commands and dispatches them.
    /// Call from `application(_:didFinishLaunchingWithOptions:)` after the UI is set up.
    static func handleLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        var format: String?
        var action: String?
        var command: String?
        var env: String?

        for i in 0..<args.count {
            switch args[i] {
            case "-CLXTestFormat" where i + 1 < args.count:
                format = args[i + 1]
            case "-CLXTestAction" where i + 1 < args.count:
                action = args[i + 1]
            case "-CLXTestCommand" where i + 1 < args.count:
                command = args[i + 1]
            case "-CLXTestEnv" where i + 1 < args.count:
                env = args[i + 1]
            default:
                break
            }
        }

        guard format != nil || command != nil else { return }

        guard let url: URL = {
            if let command = command {
                let envParam = env.map { "?env=\($0)" } ?? ""
                return URL(string: "\(scheme)://\(command)\(envParam)")
            } else {
                let act = action ?? "load"
                return URL(string: "\(scheme)://test?format=\(format!)&action=\(act)")
            }
        }() else { return }

        // Delay to ensure the UI hierarchy is fully established
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            _ = handleURL(url)
        }
    }

    /// Attempts to handle a deep link URL.
    /// - Returns: `true` if the URL was recognized and handled.
    static func handleURL(_ url: URL) -> Bool {
        guard url.scheme == scheme else { return false }

        DemoAppLogger.sharedInstance.logMessage("Deep link received: \(url.absoluteString)")

        guard let host = url.host else { return false }

        switch host {
        case "init":
            handleInit(url)
            return true
        case "test":
            handleTest(url)
            return true
        case "test-all":
            handleTestAll(url)
            return true
        default:
            DemoAppLogger.sharedInstance.logMessage("Unrecognized deep link host: \(host)")
            return false
        }
    }

    // MARK: - Route Handlers

    private static func handleInit(_ url: URL) {
        guard let tabVC = resolveTabViewController() else { return }

        let env = queryValue(forKey: "env", in: url) ?? "production"
        tabVC.selectTab(at: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let navVC = tabVC.selectedViewController as? UINavigationController,
                  let initVC = navVC.viewControllers.first else { return }

            let selector = initSelector(for: env)
            if initVC.responds(to: selector) {
                initVC.perform(selector)
            }
        }
    }

    private static func handleTest(_ url: URL) {
        guard let tabVC = resolveTabViewController() else { return }

        guard let format = queryValue(forKey: "format", in: url) else {
            DemoAppLogger.sharedInstance.logMessage("Deep link missing 'format' parameter")
            return
        }

        let action = queryValue(forKey: "action", in: url) ?? "load"

        guard let tabIndex = tabIndex(for: format) else {
            DemoAppLogger.sharedInstance.logMessage("Unknown format: \(format)")
            return
        }

        tabVC.selectTab(at: tabIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let navVC = tabVC.selectedViewController as? UINavigationController,
                  let adVC = navVC.viewControllers.first else { return }

            // "load-show" loads the ad, then auto-shows after a delay (fullscreen formats only)
            let isLoadShow = action == "load-show"
            let effectiveAction = isLoadShow ? "load" : action

            guard let sel = selector(for: format, action: effectiveAction) else { return }
            if adVC.responds(to: sel) {
                adVC.perform(sel)
            } else {
                DemoAppLogger.sharedInstance.logMessage(
                    "VC does not respond to \(NSStringFromSelector(sel)) for format=\(format), action=\(action)")
                return
            }

            if isLoadShow, let showSel = selector(for: format, action: "show"), adVC.responds(to: showSel) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 16.0) {
                    adVC.perform(showSel)
                }
            }
        }
    }

    private static func handleTestAll(_ url: URL) {
        guard let tabVC = resolveTabViewController() else { return }

        let env = queryValue(forKey: "env", in: url) ?? "production"
        DemoAppLogger.sharedInstance.logMessage("test-all: Starting — init env=\(env), then test all formats")

        tabVC.selectTab(at: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let navVC = tabVC.selectedViewController as? UINavigationController,
                  let initVC = navVC.viewControllers.first else { return }

            let sel = initSelector(for: env)
            guard initVC.responds(to: sel) else {
                DemoAppLogger.sharedInstance.logMessage("test-all: Init VC does not respond to init selector — aborting")
                return
            }

            var observer: NSObjectProtocol?
            var initCompleted = false

            observer = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("cloudXSDKInitialized"),
                object: nil,
                queue: .main
            ) { _ in
                initCompleted = true
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                DemoAppLogger.sharedInstance.logMessage("test-all: SDK initialized — resolving ATT before tests")
                resolveATTThenRunTests(tabVC: tabVC)
            }

            initVC.perform(sel)

            let timeout: TimeInterval = 30.0
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                guard !initCompleted else { return }
                if let obs = observer { NotificationCenter.default.removeObserver(obs) }
                DemoAppLogger.sharedInstance.logMessage("⚠️ test-all: SDK init timed out after \(Int(timeout))s — resolving ATT before tests")
                resolveATTThenRunTests(tabVC: tabVC)
            }
        }
    }

    /// ATT must be resolved before ad loading — ads without ATT authorization
    /// may receive no fill. Request authorization if still undetermined, then
    /// proceed to the test sequence regardless of the user's choice.
    private static func resolveATTThenRunTests(tabVC: AdDemoTabViewController) {
        if #available(iOS 14, *),
           ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            DemoAppLogger.sharedInstance.logMessage("test-all: ATT not determined — requesting authorization")
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    logATTStatus()
                    DemoAppLogger.sharedInstance.logMessage("test-all: ATT resolved — starting ad format tests")
                    runTestSequence(tabVC: tabVC)
                }
            }
            return
        }
        logATTStatus()
        DemoAppLogger.sharedInstance.logMessage("test-all: ATT already resolved — starting ad format tests")
        runTestSequence(tabVC: tabVC)
    }

    private static func logATTStatus() {
        guard #available(iOS 14, *) else {
            DemoAppLogger.sharedInstance.logMessage("ATT_STATUS: not_available (pre-iOS 14)")
            return
        }
        let status = ATTrackingManager.trackingAuthorizationStatus
        let name: String
        switch status {
        case .authorized:      name = "authorized"
        case .denied:          name = "denied"
        case .restricted:      name = "restricted"
        case .notDetermined:   name = "notDetermined"
        @unknown default:      name = "unknown"
        }
        DemoAppLogger.sharedInstance.logMessage("ATT_STATUS: \(name)")
    }

    private static let adLoadTimeout: TimeInterval = 30.0
    private static let revenueTimeout: TimeInterval = 5.0
    private static let fullscreenDismissTimeout: TimeInterval = 90.0
    private static let pollInterval: TimeInterval = 1.0
    private static let maxLoadRetries = 3
    private static let retryDelay: TimeInterval = 3.0

    private static func runTestSequence(tabVC: AdDemoTabViewController) {
        let formats: [(format: String, shouldShow: Bool)] = [
            ("banner", false),
            ("mrec", false),
            ("interstitial", true),
            ("rewarded", true),
            ("rewarded-interstitial", true),
        ]

        runFormat(formats, at: 0, tabVC: tabVC)
    }

    private static func runFormat(_ formats: [(format: String, shouldShow: Bool)],
                                  at index: Int,
                                  tabVC: AdDemoTabViewController) {
        guard index < formats.count else {
            DemoAppLogger.sharedInstance.logMessage("test-all sequence complete")
            return
        }

        let entry = formats[index]
        let format = entry.format
        let shouldShow = entry.shouldShow

        DemoAppLogger.sharedInstance.logMessage(
            "test-all [\(index + 1)/\(formats.count)]: Testing \(format)")

        let _ = dismissAlertReturningClassName()

        guard let tabIdx = tabIndex(for: format),
              tabIdx < tabVC.viewControllers?.count ?? 0 else {
            DemoAppLogger.sharedInstance.logMessage("test-all: Skipping \(format) — invalid tab index")
            runFormat(formats, at: index + 1, tabVC: tabVC)
            return
        }

        tabVC.selectTab(at: tabIdx)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismissAnyOverlay()

            guard let navVC = tabVC.selectedViewController as? UINavigationController,
                  let adVC = navVC.viewControllers.first,
                  let loadSel = selector(for: format, action: "load"),
                  adVC.responds(to: loadSel) else {
                DemoAppLogger.sharedInstance.logMessage("test-all: VC does not respond to load for \(format)")
                runFormat(formats, at: index + 1, tabVC: tabVC)
                return
            }

            loadAdWithRetries(
                maxRetries: maxLoadRetries,
                format: format,
                shouldShow: shouldShow,
                adVC: adVC,
                loadSel: loadSel,
                formats: formats,
                atIndex: index,
                tabVC: tabVC,
                attempt: 1
            )
        }
    }

    private static func loadAdWithRetries(
        maxRetries: Int,
        format: String,
        shouldShow: Bool,
        adVC: UIViewController,
        loadSel: Selector,
        formats: [(format: String, shouldShow: Bool)],
        atIndex index: Int,
        tabVC: AdDemoTabViewController,
        attempt: Int
    ) {
        DemoAppLogger.sharedInstance.logMessage(
            "test-all: Loading \(format) (attempt \(attempt)/\(maxRetries))...")

        adVC.perform(loadSel)

        guard let stateVC = adVC as? (UIViewController & AdStateManaging) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + adLoadTimeout) {
                runFormat(formats, at: index + 1, tabVC: tabVC)
            }
            return
        }

        waitForLoadCompletion(stateVC, timeout: adLoadTimeout) { loaded in
            if loaded {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: ✅ \(format) loaded successfully (attempt \(attempt))")

                let afterRevenue = {
                    if shouldShow {
                        showAndWaitForDismissal(format: format, adVC: adVC) {
                            runFormat(formats, at: index + 1, tabVC: tabVC)
                        }
                    } else {
                        runFormat(formats, at: index + 1, tabVC: tabVC)
                    }
                }

                waitForRevenueCallback(stateVC, timeout: revenueTimeout, format: format) {
                    afterRevenue()
                }
            } else if attempt < maxRetries {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: ⚠️ \(format) load failed (attempt \(attempt)/\(maxRetries)) — retrying in \(Int(retryDelay))s...")

                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                    loadAdWithRetries(
                        maxRetries: maxRetries,
                        format: format,
                        shouldShow: shouldShow,
                        adVC: adVC,
                        loadSel: loadSel,
                        formats: formats,
                        atIndex: index,
                        tabVC: tabVC,
                        attempt: attempt + 1
                    )
                }
            } else {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: ❌ \(format) failed after \(maxRetries) attempts — moving on")
                runFormat(formats, at: index + 1, tabVC: tabVC)
            }
        }
    }

    // MARK: - Polling: Wait for Ad Load

    private static func waitForLoadCompletion(
        _ adVC: UIViewController & AdStateManaging,
        timeout: TimeInterval,
        completion: @escaping (Bool) -> Void
    ) {
        pollLoadState(adVC, elapsed: 0, timeout: timeout, completion: completion)
    }

    private static func pollLoadState(
        _ adVC: UIViewController & AdStateManaging,
        elapsed: TimeInterval,
        timeout: TimeInterval,
        completion: @escaping (Bool) -> Void
    ) {
        if !adVC.isLoading && elapsed > 0 {
            var loaded = false
            if let baseVC = adVC as? BaseAdViewController {
                let text = baseVC.statusLabel.text ?? ""
                let hasFailure = text.contains("Failed") || text.contains("Error") ||
                                 text.contains("No Ad") || text.contains("No Fill")
                let isGreen = baseVC.statusIndicator.backgroundColor == .systemGreen
                loaded = isGreen && !hasFailure
            }
            completion(loaded)
            return
        }

        if elapsed >= timeout {
            completion(false)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) {
            dismissAnyOverlay()
            pollLoadState(adVC, elapsed: elapsed + pollInterval, timeout: timeout, completion: completion)
        }
    }

    // MARK: - Polling: Wait for Revenue Callback

    private static func waitForRevenueCallback(
        _ adVC: UIViewController & AdStateManaging,
        timeout: TimeInterval,
        format: String,
        completion: @escaping () -> Void
    ) {
        pollRevenueState(adVC, elapsed: 0, timeout: timeout, format: format, completion: completion)
    }

    private static func pollRevenueState(
        _ adVC: UIViewController & AdStateManaging,
        elapsed: TimeInterval,
        timeout: TimeInterval,
        format: String,
        completion: @escaping () -> Void
    ) {
        if adVC.receivedCallbacks.contains(.revenueReceived) {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: ✅ \(format) — didPayRevenueForAd received (\(String(format: "%.1f", elapsed))s)")
            completion()
            return
        }

        if elapsed >= timeout {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: ⚠️ \(format) — didPayRevenueForAd not received within \(Int(timeout))s")
            completion()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pollRevenueState(adVC, elapsed: elapsed + 0.5, timeout: timeout, format: format, completion: completion)
        }
    }

    // MARK: - Show + Wait for Fullscreen Dismissal

    private static func showAndWaitForDismissal(
        format: String,
        adVC: UIViewController,
        completion: @escaping () -> Void
    ) {
        guard let showSel = selector(for: format, action: "show"),
              adVC.responds(to: showSel) else {
            DemoAppLogger.sharedInstance.logMessage("test-all: VC does not respond to show for \(format)")
            completion()
            return
        }

        DemoAppLogger.sharedInstance.logMessage("test-all: Showing \(format)...")
        adVC.perform(showSel)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if dismissAnyOverlay() {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: ⚠️ \(format) show produced an alert — dismissed")
                completion()
                return
            }

            waitForFullscreenDismissal(elapsed: 0, timeout: fullscreenDismissTimeout) {
                DemoAppLogger.sharedInstance.logMessage("test-all: \(format) fullscreen dismissed")
                completion()
            }
        }
    }

    private static func waitForFullscreenDismissal(
        elapsed: TimeInterval,
        timeout: TimeInterval,
        completion: @escaping () -> Void
    ) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            completion()
            return
        }

        let presented = rootVC.presentedViewController

        if presented == nil || presented is UIAlertController {
            dismissAnyOverlay()
            completion()
            return
        }

        if elapsed >= timeout {
            DemoAppLogger.sharedInstance.logMessage("test-all: Fullscreen dismiss timed out — force-dismissing")
            rootVC.dismiss(animated: false) {
                completion()
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            waitForFullscreenDismissal(elapsed: elapsed + 2.0, timeout: timeout, completion: completion)
        }
    }

    // MARK: - UI State Logging

    private static func logUIState(dismissedClassName: String?) {
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController

        let presented = rootVC?.presentedViewController
        let presentedInfo = presented.map { String(describing: type(of: $0)) } ?? "none"

        if let dismissed = dismissedClassName {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: UI state — dismissed \(dismissed), now presented: \(presentedInfo)")
        } else {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: UI state — presented: \(presentedInfo)")
        }
    }

    // MARK: - Alert Dismissal

    /// Dismisses only UIAlertController instances. Safe to call at any time.
    @discardableResult
    private static func dismissAnyOverlay() -> Bool {
        return dismissAlertReturningClassName() != nil
    }

    private static func dismissAlertReturningClassName() -> String? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else { return nil }
        return dismissAlert(from: rootVC)
    }

    private static func dismissAlert(from vc: UIViewController) -> String? {
        guard let presented = vc.presentedViewController else {
            if let tabVC = vc as? UITabBarController {
                return tabVC.selectedViewController.flatMap { dismissAlert(from: $0) }
            }
            if let navVC = vc as? UINavigationController {
                return navVC.topViewController.flatMap { dismissAlert(from: $0) }
            }
            return nil
        }

        if let alert = presented as? UIAlertController {
            let title = alert.title ?? "(untitled)"
            presented.dismiss(animated: false)
            return "UIAlertController(\(title))"
        }

        return dismissAlert(from: presented)
    }

    // MARK: - Tab Resolution

    private static func tabIndex(for format: String) -> Int? {
        let map: [String: Int] = [
            "banner": 1,
            "mrec": 4,
            "interstitial": 2,
            "rewarded": 3,
            "rewarded-interstitial": 5,
        ]
        return map[format]
    }

    private static func selector(for format: String, action: String) -> Selector? {
        let isShow = action == "show"

        switch format {
        case "banner":
            return NSSelectorFromString("loadBannerAd")
        case "mrec":
            return NSSelectorFromString("loadMRECAd")
        case "interstitial":
            return NSSelectorFromString(isShow ? "showInterstitialAd" : "loadInterstitialAd")
        case "rewarded":
            return NSSelectorFromString(isShow ? "showRewardedAd" : "loadRewardedAd")
        case "rewarded-interstitial":
            return NSSelectorFromString(isShow ? "showRewardedInterstitialAd" : "loadRewardedInterstitialAd")
        default:
            return nil
        }
    }

    private static func initSelector(for env: String) -> Selector {
        switch env {
        case "staging": return NSSelectorFromString("initializeWithStagingEnvironment")
        case "dev": return NSSelectorFromString("initializeWithDevEnvironment")
        default: return NSSelectorFromString("initializeWithProductionEnvironment")
        }
    }

    // MARK: - Helpers

    private static func resolveTabViewController() -> AdDemoTabViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            DemoAppLogger.sharedInstance.logMessage("Could not resolve key window for deep link")
            return nil
        }

        if let tabVC = window.rootViewController as? AdDemoTabViewController {
            return tabVC
        }
        if let navVC = window.rootViewController as? UINavigationController,
           let tabVC = navVC.topViewController as? AdDemoTabViewController {
            return tabVC
        }

        DemoAppLogger.sharedInstance.logMessage("Could not resolve AdDemoTabViewController for deep link")
        return nil
    }

    private static func queryValue(forKey key: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == key })?
            .value
    }
}
