import UIKit
import AppTrackingTransparency
import WebKit
import SafariServices
import StoreKit

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

        // Fallback: on iOS 26+, simctl launch writes -key value pairs to
        // NSUserDefaults volatile domain but not ProcessInfo.arguments.
        if format == nil && command == nil {
            let defaults = UserDefaults.standard
            command = defaults.string(forKey: "CLXTestCommand")
            format = defaults.string(forKey: "CLXTestFormat")
            action = defaults.string(forKey: "CLXTestAction")
            env = defaults.string(forKey: "CLXTestEnv")
        }

        guard format != nil || command != nil else {
            DemoAppLogger.sharedInstance.logMessage("handleLaunchArguments: No command or format found in args or defaults")
            return
        }

        DemoAppLogger.sharedInstance.logMessage("handleLaunchArguments: command=\(command ?? "nil") format=\(format ?? "nil") env=\(env ?? "nil")")

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

            if let selector = resolveInitSelector(for: initVC, env: env) {
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

        guard let tabIndex = tabIndex(for: format, in: tabVC) else {
            DemoAppLogger.sharedInstance.logMessage("Unknown or unavailable format: \(format)")
            return
        }

        tabVC.selectTab(at: tabIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let adVC = vcAtTabIndex(tabIndex, in: tabVC) else { return }

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

            guard let sel = resolveInitSelector(for: initVC, env: env) else {
                DemoAppLogger.sharedInstance.logMessage("test-all: Init VC does not respond to any init selector — aborting")
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
    private static let revenuePollInterval: TimeInterval = 0.5
    private static let fullscreenDismissTimeout: TimeInterval = 90.0
    private static let pollInterval: TimeInterval = 1.0
    private static let maxLoadRetries = 3
    private static let retryDelay: TimeInterval = 3.0
    private static let clickTimeout: TimeInterval = 10.0
    private static let clickPollInterval: TimeInterval = 0.5
    private static let clickOverlayDismissDelay: TimeInterval = 2.0

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

        let dismissedClassName = dismissAlertReturningClassName()
        logUIState(dismissedClassName: dismissedClassName)

        guard let tabIdx = tabIndex(for: format, in: tabVC),
              tabIdx < tabVC.viewControllers?.count ?? 0 else {
            DemoAppLogger.sharedInstance.logMessage("test-all: Skipping \(format) — no matching tab in this app")
            runFormat(formats, at: index + 1, tabVC: tabVC)
            return
        }

        tabVC.selectTab(at: tabIdx)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismissAnyOverlay()

            guard let adVC = vcAtTabIndex(tabIdx, in: tabVC),
                  let loadSel = selector(for: format, action: "load"),
                  adVC.responds(to: loadSel) else {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: VC does not respond to load for \(format)")
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

                if shouldShow {
                    // Fullscreen: revenue fires on impression, so show first then verify revenue after dismissal
                    showAndWaitForDismissal(format: format, adVC: adVC) {
                        waitForRevenueCallback(stateVC, timeout: revenueTimeout, format: format) {
                            runFormat(formats, at: index + 1, tabVC: tabVC)
                        }
                    }
                } else {
                    // Banner/MREC: revenue fires after auto-display on load, then click test
                    waitForRevenueCallback(stateVC, timeout: revenueTimeout, format: format) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            performInAppClick(on: adVC, format: format)
                            waitForClickCallback(stateVC, timeout: clickTimeout, format: format) { clicked in
                                if clicked {
                                    dismissClickOverlay {
                                        runFormat(formats, at: index + 1, tabVC: tabVC)
                                    }
                                } else {
                                    runFormat(formats, at: index + 1, tabVC: tabVC)
                                }
                            }
                        }
                    }
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

        DispatchQueue.main.asyncAfter(deadline: .now() + revenuePollInterval) {
            pollRevenueState(adVC, elapsed: elapsed + revenuePollInterval, timeout: timeout, format: format, completion: completion)
        }
    }

    // MARK: - Fullscreen Dismiss Detection
    //
    // Multi-tier dismiss strategy:
    // All interaction happens IN-PROCESS via synthetic UITouch and JS injection.
    // No external tools (cliclick, osascript) are used — the simulator does NOT need
    // to be visible or frontmost. This enables parallel test execution on multiple
    // simulators from different Cursor agents without window management.
    //
    // Tier escalation is based on ACTUAL failed attempts, not wall-clock time.
    // This avoids skipping tiers when a close button appears late (e.g., after a
    // 15-30s countdown). Each tier gets a fair chance before escalating.
    //
    // Tier 1: tapView (UIControl sendActions / accessibilityActivate) on top candidate
    // Tier 2: Synthetic UITouch on top candidate (reaches gesture recognizers)
    // Tier 3: JS click injection in WKWebView at candidate coordinates
    // Tier 4: JS blind corner taps (when no native candidates found — close button
    //         is rendered entirely within the WKWebView)
    // Force dismiss: programmatic dismiss(animated:) after exhausting tiers

    private static var dismissTapAttempts: Int = 0
    private static var dismissNoCandidatePolls: Int = 0

    private static let dismissCandidateScoreThreshold = 4
    private static let dismissInitialDelay: TimeInterval = 5.0
    private static let tier2TapThreshold = 2
    private static let tier3TapThreshold = 5
    private static let forceDismissTapThreshold = 12
    private static let tier4NoCandidateThreshold = 5
    private static let tier4MinElapsed: TimeInterval = 20.0
    private static let forceNoCandidateThreshold = 15

    private static func findDismissCandidates(in rootView: UIView) -> [UIView] {
        var candidates: [UIView] = []
        collectDismissCandidates(from: rootView, into: &candidates, insideWebView: false)
        candidates.sort { scoreDismissCandidate($0) > scoreDismissCandidate($1) }
        return candidates
    }

    private static func collectDismissCandidates(from view: UIView,
                                                  into candidates: inout [UIView],
                                                  insideWebView: Bool) {
        guard !view.isHidden, view.alpha >= 0.1, view.isUserInteractionEnabled else { return }

        if insideWebView || view is WKWebView {
            for subview in view.subviews {
                collectDismissCandidates(from: subview, into: &candidates, insideWebView: true)
            }
            return
        }

        if scoreDismissCandidate(view) >= dismissCandidateScoreThreshold {
            candidates.append(view)
        }

        for subview in view.subviews {
            collectDismissCandidates(from: subview, into: &candidates, insideWebView: false)
        }
    }

    /// Heuristic scoring for likely close/dismiss buttons in fullscreen ad views.
    /// Higher score = more likely to be a close button. Threshold: dismissCandidateScoreThreshold.
    ///
    /// Scoring logic:
    /// - Small size (≤50x50) in a top corner = classic close button placement (+3 size, +3 position)
    /// - Accessibility labels/titles containing "close", "skip", "x", ">>" = strong signal (+5)
    /// - Non-dismiss elements (AdChoices, mute, info, learn more, install) = heavy penalty (-10)
    /// - UIButton/UIControl or tap gesture recognizer = minor bonus (+1)
    private static func scoreDismissCandidate(_ view: UIView) -> Int {
        var score = 0

        let frameInWindow = view.convert(view.bounds, to: nil)
        let w = frameInWindow.width
        let h = frameInWindow.height

        if w > 0 && h > 0 && w <= 50 && h <= 50 {
            score += 3
        } else if w > 0 && h > 0 && w <= 60 && h <= 60 {
            score += 2
        }

        let screenWidth = UIScreen.main.bounds.width
        let nearLeftEdge = frameInWindow.origin.x < 80
        let nearRightEdge = frameInWindow.maxX > screenWidth - 80
        let nearTop = frameInWindow.origin.y < 100
        if (nearLeftEdge || nearRightEdge) && nearTop {
            score += 3
        }

        let className = String(describing: type(of: view)).lowercased()
        let label = view.accessibilityLabel?.lowercased() ?? ""
        let title = (view as? UIButton)?.title(for: .normal)?.lowercased() ?? ""

        // Positive: close/skip/dismiss indicators
        if !label.isEmpty {
            if label.contains("close") || label.contains("skip") ||
               label.contains("dismiss") || label.contains("forward") ||
               label.contains("done") || label == "x" || label == ">>" {
                score += 5
            }
        }
        if title.contains("close") || title.contains("skip") ||
           title.contains("×") || title.contains("✕") ||
           title == "x" || title == ">>" {
            score += 5
        }

        // Penalize non-dismiss interactive elements
        if label.contains("choice") || label.contains("mute") ||
           label.contains("audio") || label.contains("info") ||
           label.contains("report") || label.contains("advertiser") ||
           label.contains("privacy") || label.contains("learn more") ||
           label.contains("install") {
            score -= 10
        }
        if className.contains("adchoice") || className.contains("mute") ||
           className.contains("privacy") {
            score -= 10
        }

        if view is UIControl {
            score += 1
        }

        if let gestures = view.gestureRecognizers {
            if gestures.contains(where: { $0 is UITapGestureRecognizer }) {
                score += 1
            }
        }

        return score
    }

    /// Attempts to programmatically activate a view using public APIs only.
    /// Used by dismiss candidate tapping — synthetic UITouch (CLXSyntheticTouch)
    /// handles the cases where these strategies are insufficient.
    private static func tapView(_ view: UIView) -> Bool {
        if let control = view as? UIControl {
            control.sendActions(for: .touchUpInside)
            return true
        }

        if view.accessibilityActivate() {
            return true
        }

        // Walk up the responder chain for a UIControl ancestor
        var responder: UIResponder? = view.next
        while let current = responder {
            if let control = current as? UIControl {
                control.sendActions(for: .touchUpInside)
                return true
            }
            responder = current.next
        }

        return false
    }

    /// Synthesizes a real UITouch tap at a window-coordinate point.
    /// Delegates to the ObjC CLXSyntheticTouch helper which calls private UIKit
    /// APIs via objc_msgSend. Suitable only for demo/test apps.
    private static func synthesizeTap(at windowPoint: CGPoint, in window: UIWindow) -> Bool {
        return CLXSyntheticTouch.tap(at: windowPoint, in: window)
    }

    /// Taps a specific point in a WKWebView by injecting JavaScript touch + click events.
    /// - Parameter point: A point in window (device) coordinate space.
    private static func tapPointInWebView(_ webView: WKWebView, atDevicePoint point: CGPoint) {
        let localPoint = webView.convert(point, from: nil)
        tapPointInWebViewLocal(webView, at: localPoint)
    }

    /// Taps a specific point in a WKWebView using local (webView) coordinates.
    private static func tapPointInWebViewLocal(_ webView: WKWebView, at point: CGPoint) {
        let js = """
        (function(){
            var x=\(point.x),y=\(point.y);
            var el=document.elementFromPoint(x,y);
            if(!el) return 'none';
            try{
                var t=new Touch({identifier:Date.now(),target:el,clientX:x,clientY:y});
                el.dispatchEvent(new TouchEvent('touchstart',{bubbles:true,cancelable:true,touches:[t],targetTouches:[t],changedTouches:[t]}));
                el.dispatchEvent(new TouchEvent('touchend',{bubbles:true,cancelable:true,touches:[],targetTouches:[],changedTouches:[t]}));
            }catch(e){}
            el.click();
            return el.tagName;
        })()
        """
        webView.evaluateJavaScript(js) { result, _ in
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: WKWebView JS click at (\(Int(point.x)),\(Int(point.y))) → \(result ?? "error")")
        }
    }

    private static func findWebView(in view: UIView) -> WKWebView? {
        if let webView = view as? WKWebView { return webView }
        for subview in view.subviews {
            if let found = findWebView(in: subview) { return found }
        }
        return nil
    }

    private static func findFirstTappableSubview(_ view: UIView) -> UIView? {
        for subview in view.subviews {
            if subview.isHidden || subview.alpha < 0.1 || !subview.isUserInteractionEnabled { continue }
            if subview is UIControl { return subview }
            if let grs = subview.gestureRecognizers, !grs.isEmpty { return subview }
            if let found = findFirstTappableSubview(subview) { return found }
        }
        return nil
    }

    private static func tapTopDismissCandidate(_ candidates: [UIView]) -> Bool {
        guard let top = candidates.first else { return false }

        let tapped = tapView(top)
        if tapped {
            let frame = top.convert(top.bounds, to: nil)
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: Dismiss Tier 1 — tapped candidate (\(type(of: top))) at (\(Int(frame.midX)), \(Int(frame.midY))) score=\(scoreDismissCandidate(top))")
        }
        return tapped
    }

    private static func tapAllDismissCandidates(_ candidates: [UIView]) -> Bool {
        var anyTapped = false
        for candidate in candidates {
            if tapView(candidate) {
                let frame = candidate.convert(candidate.bounds, to: nil)
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: Dismiss Tier 2 — tapped candidate (\(type(of: candidate))) at (\(Int(frame.midX)), \(Int(frame.midY)))")
                anyTapped = true
            }
        }
        return anyTapped
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
        if elapsed == 0 {
            dismissTapAttempts = 0
            dismissNoCandidatePolls = 0
        }

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

        // Dismiss nested overlays (e.g., AdChoices, privacy sheets) that appear
        // on top of the fullscreen ad and block interaction with the close button.
        if let nestedPresented = presented?.presentedViewController,
           !(nestedPresented is UIAlertController) {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: Dismissing nested overlay (\(String(describing: type(of: nestedPresented)))) on top of fullscreen ad")
            presented?.dismiss(animated: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    waitForFullscreenDismissal(elapsed: elapsed + 0.5, timeout: timeout, completion: completion)
                }
            }
            return
        }

        if elapsed >= timeout {
            DemoAppLogger.sharedInstance.logMessage("test-all: Fullscreen dismiss timed out — force-dismissing")
            rootVC.dismiss(animated: false) {
                completion()
            }
            return
        }

        if elapsed >= dismissInitialDelay, let presentedView = presented?.view {
            let candidates = findDismissCandidates(in: presentedView)

            DemoAppLogger.sharedInstance.logMessage(
                "test-all: Dismiss scan elapsed=\(Int(elapsed)) candidates=\(candidates.count) tapAttempts=\(dismissTapAttempts) noCandidatePolls=\(dismissNoCandidatePolls) presented=\(type(of: presented!))")

            if !candidates.isEmpty {
                if dismissTapAttempts >= forceDismissTapThreshold {
                    DemoAppLogger.sharedInstance.logMessage(
                        "test-all: Force-dismiss after \(dismissTapAttempts) failed tap attempts")
                    rootVC.dismiss(animated: false) { completion() }
                    return
                } else if dismissTapAttempts < tier2TapThreshold {
                    _ = tapTopDismissCandidate(candidates)
                } else if dismissTapAttempts < tier3TapThreshold {
                    // Tier 2: Synthesize a real UITouch on the top candidate
                    let top = candidates[0]
                    let topFrame = top.convert(top.bounds, to: nil)
                    let topCenter = CGPoint(x: topFrame.midX, y: topFrame.midY)
                    let win = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })
                    if let win = win, synthesizeTap(at: topCenter, in: win) {
                        DemoAppLogger.sharedInstance.logMessage(
                            "test-all: Dismiss Tier 2 — synthetic UITouch at (\(Int(topCenter.x)),\(Int(topCenter.y)))")
                    } else {
                        _ = tapAllDismissCandidates(candidates)
                    }
                } else {
                    // Tier 3: JS click on top candidate's coordinates in WKWebView
                    let top = candidates[0]
                    let frame = top.convert(top.bounds, to: nil)
                    let center = CGPoint(x: frame.midX, y: frame.midY)
                    if let webView = findWebView(in: presented!.view) {
                        tapPointInWebView(webView, atDevicePoint: center)
                        DemoAppLogger.sharedInstance.logMessage(
                            "test-all: Dismiss Tier 3 — JS click on WKWebView at candidate coords")
                    } else {
                        _ = tapAllDismissCandidates(candidates)
                        DemoAppLogger.sharedInstance.logMessage(
                            "test-all: Dismiss Tier 3 — re-tapping all candidates (no WKWebView found)")
                    }
                }
                dismissTapAttempts += 1
            } else {
                dismissNoCandidatePolls += 1
                if dismissNoCandidatePolls >= forceNoCandidateThreshold {
                    DemoAppLogger.sharedInstance.logMessage(
                        "test-all: Force-dismiss after \(dismissNoCandidatePolls) no-candidate polls")
                    rootVC.dismiss(animated: false) { completion() }
                    return
                } else if dismissNoCandidatePolls >= tier4NoCandidateThreshold && elapsed >= tier4MinElapsed {
                    if let webView = findWebView(in: presented!.view) {
                        let wvW = webView.bounds.width
                        tapPointInWebViewLocal(webView, at: CGPoint(x: wvW - 25, y: 25))
                        tapPointInWebViewLocal(webView, at: CGPoint(x: 25, y: 25))
                        tapPointInWebViewLocal(webView, at: CGPoint(x: wvW - 25, y: 55))
                        tapPointInWebViewLocal(webView, at: CGPoint(x: 25, y: 55))
                        DemoAppLogger.sharedInstance.logMessage(
                            "test-all: Dismiss Tier 4 — JS blind corner taps in WKWebView")
                    } else {
                        DemoAppLogger.sharedInstance.logMessage(
                            "test-all: Dismiss Tier 4 — no candidates, no WKWebView — force dismiss")
                        rootVC.dismiss(animated: false) { completion() }
                        return
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            waitForFullscreenDismissal(elapsed: elapsed + 2.0, timeout: timeout, completion: completion)
        }
    }

    // MARK: - Click Testing: Log Target & Poll
    //
    // Multi-strategy click approach:
    // Different ad SDKs track clicks differently. Some use transparent UIView overlays
    // (returned by hitTest), others use WKWebView navigation interception, and others
    // use UIControl/gesture recognizer targets. We fire ALL strategies on every click
    // rather than exiting after the first "success" — a strategy can dispatch without
    // error but still not trigger the SDK's click handler.
    //
    // Strategy 1 (hitTest target) is closest to a real user tap and works for most SDKs.
    // Strategy 2 (WebKit content view) bypasses overlays and reaches WKWebView GR targets.
    // Strategy 3 (JS injection) works when the ad is a web creative with click handlers.
    // Strategy 4 (UIControl/accessibility) is a fallback for native-rendered ads.

    private static func performInAppClick(on adVC: UIViewController, format: String) {
        guard let stateVC = adVC as? (UIViewController & AdStateManaging) else { return }

        guard let adView = stateVC.adViewForClickTesting() else {
            DemoAppLogger.sharedInstance.logMessage("test-all: No ad view available for click testing on \(format)")
            return
        }

        let frame = adView.convert(adView.bounds, to: nil)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        DemoAppLogger.sharedInstance.logMessage(
            "test-all: Clicking \(format) ad in-app at (\(Int(center.x)),\(Int(center.y))) size=\(Int(frame.width))x\(Int(frame.height))")

        // Strategy 1: Synthetic UITouch on the system hitTest target.
        if let window = adView.window {
            let hitTarget = window.hitTest(center, with: nil)
            if let target = hitTarget {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: \(format) click — hitTest target: \(type(of: target)) frame=\(target.convert(target.bounds, to: nil))")
                _ = CLXSyntheticTouch.tap(at: center, on: target, in: window)
            }
        }

        // Strategy 2: Synthetic UITouch on the deepest WebKit content view.
        if let window = adView.window {
            _ = CLXSyntheticTouch.tap(at: center, in: window)
        }

        // Strategy 3: JS click injection on any WKWebView inside the ad view.
        if let webView = findWebView(in: adView) {
            tapPointInWebView(webView, atDevicePoint: center)
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: \(format) click — JS injection in \(type(of: webView))")
        }

        // Strategy 4: UIControl sendActions / accessibility
        if let tappable = findFirstTappableSubview(adView), tapView(tappable) {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: \(format) click — tappable subview (\(type(of: tappable)))")
        } else if adView.accessibilityActivate() {
            DemoAppLogger.sharedInstance.logMessage("test-all: \(format) click — accessibilityActivate")
        }

        DemoAppLogger.sharedInstance.logMessage("test-all: \(format) click — all strategies dispatched")
    }

    private static func waitForClickCallback(
        _ adVC: UIViewController & AdStateManaging,
        timeout: TimeInterval,
        format: String,
        completion: @escaping (Bool) -> Void
    ) {
        pollClickState(adVC, elapsed: 0, timeout: timeout, format: format, completion: completion)
    }

    private static func pollClickState(
        _ adVC: UIViewController & AdStateManaging,
        elapsed: TimeInterval,
        timeout: TimeInterval,
        format: String,
        completion: @escaping (Bool) -> Void
    ) {
        if adVC.receivedCallbacks.contains(.clicked) {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: ✅ \(format) — didClickAd received (\(String(format: "%.1f", elapsed))s)")
            completion(true)
            return
        }

        if elapsed >= timeout {
            DemoAppLogger.sharedInstance.logMessage(
                "test-all: ⚠️ \(format) — didClickAd not received within \(Int(timeout))s")
            completion(false)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + clickPollInterval) {
            pollClickState(adVC, elapsed: elapsed + clickPollInterval, timeout: timeout, format: format, completion: completion)
        }
    }

    /// Dismisses post-click overlays (SFSafariViewController, SKStoreProductViewController)
    /// that ad SDKs present after a click. Polls because the app may be in the background
    /// (click opened Safari or App Store) — dispatch_after still fires but UIKit state
    /// is frozen until the app returns to foreground. The test-runner.sh re-foregrounds
    /// the app by terminating Safari/App Store after detecting a click event in the logs.
    private static func dismissClickOverlay(completion: @escaping () -> Void) {
        pollDismissClickOverlay(elapsed: 0, completion: completion)
    }

    private static func pollDismissClickOverlay(elapsed: TimeInterval, completion: @escaping () -> Void) {
        let maxWait: TimeInterval = 10
        let pollInterval: TimeInterval = 1

        if elapsed >= maxWait {
            DemoAppLogger.sharedInstance.logMessage("test-all: Click overlay dismiss — timed out, continuing")
            completion()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) {
            if UIApplication.shared.applicationState != .active {
                DemoAppLogger.sharedInstance.logMessage("test-all: Click overlay — app in background, waiting...")
                pollDismissClickOverlay(elapsed: elapsed + pollInterval, completion: completion)
                return
            }

            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }),
                  let rootVC = window.rootViewController else {
                completion()
                return
            }

            let presented = rootVC.presentedViewController

            if presented is SFSafariViewController || presented is SKStoreProductViewController {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: Dismissing click overlay (\(type(of: presented!)))")
                rootVC.dismiss(animated: false) { completion() }
                return
            }

            if let presented = presented,
               !(presented is UIAlertController),
               !(presented is UITabBarController) {
                DemoAppLogger.sharedInstance.logMessage(
                    "test-all: Dismissing unknown click overlay (\(type(of: presented)))")
                rootVC.dismiss(animated: false) { completion() }
                return
            }

            completion()
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

    /// Scans the tab bar's viewControllers array and matches by VC class name
    /// rather than hardcoded indices, so the router works regardless of which
    /// formats an app includes or how its tabs are ordered.
    private static func tabIndex(for format: String, in tabVC: AdDemoTabViewController) -> Int? {
        let classNameMap: [String: String] = [
            "banner":                "BannerViewController",
            "mrec":                  "MRECViewController",
            "interstitial":          "InterstitialViewController",
            "rewarded":              "RewardedViewController",
            "rewarded-interstitial": "RewardedInterstitialViewController",
        ]

        guard let targetClassName = classNameMap[format],
              let vcs = tabVC.viewControllers else { return nil }

        for (index, vc) in vcs.enumerated() {
            let contentVC: UIViewController?
            if let navVC = vc as? UINavigationController {
                contentVC = navVC.viewControllers.first
            } else {
                contentVC = vc
            }
            guard let contentVC = contentVC else { continue }
            if String(describing: type(of: contentVC)) == targetClassName {
                return index
            }
        }

        DemoAppLogger.sharedInstance.logMessage(
            "tabIndex(for:): No tab found for '\(format)' (expected VC class: \(targetClassName))")
        return nil
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

    /// Returns the best init selector the VC responds to: environment-specific first,
    /// then generic initializeSDK as fallback for apps with a single init button.
    private static func resolveInitSelector(for vc: UIViewController, env: String) -> Selector? {
        let envSel = initSelector(for: env)
        if vc.responds(to: envSel) { return envSel }
        let genericSel = NSSelectorFromString("initializeSDK")
        if vc.responds(to: genericSel) { return genericSel }
        return nil
    }

    // MARK: - VC Resolution

    /// Resolves the content view controller at a given tab index, handling
    /// UINavigationController wrapping and the "More" overflow tab correctly.
    private static func vcAtTabIndex(_ tabIndex: Int, in tabVC: AdDemoTabViewController) -> UIViewController? {
        guard let vcs = tabVC.viewControllers, tabIndex >= 0, tabIndex < vcs.count else { return nil }

        let vc = vcs[tabIndex]
        if let navVC = vc as? UINavigationController, let root = navVC.viewControllers.first {
            return root
        }
        if vc is UINavigationController { } else {
            return vc
        }

        // Fallback for "More" tab items: the system may move the content VC
        // to moreNavigationController, leaving the original nav stack empty.
        if tabVC.selectedIndex == tabIndex {
            let top = tabVC.moreNavigationController.topViewController
            if let navVC = top as? UINavigationController, let root = navVC.viewControllers.first {
                return root
            }
            return top
        }

        return nil
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
