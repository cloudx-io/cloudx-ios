import UIKit

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

        for i in 0..<args.count {
            switch args[i] {
            case "-CLXTestFormat" where i + 1 < args.count:
                format = args[i + 1]
            case "-CLXTestAction" where i + 1 < args.count:
                action = args[i + 1]
            case "-CLXTestCommand" where i + 1 < args.count:
                command = args[i + 1]
            default:
                break
            }
        }

        guard format != nil || command != nil else { return }

        let url: URL
        if let command = command {
            url = URL(string: "\(scheme)://\(command)")!
        } else {
            let act = action ?? "load"
            url = URL(string: "\(scheme)://test?format=\(format!)&action=\(act)")!
        }

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
            handleTestAll()
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

        guard let tabIndex = tabIndex(for: format), tabIndex >= 0 else {
            DemoAppLogger.sharedInstance.logMessage("Unknown format: \(format)")
            return
        }

        tabVC.selectTab(at: tabIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let navVC = tabVC.selectedViewController as? UINavigationController,
                  let adVC = navVC.viewControllers.first else { return }

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

    private static func handleTestAll() {
        guard let tabVC = resolveTabViewController() else { return }

        let steps: [(format: String, action: String, delay: TimeInterval)] = [
            ("banner", "load", 1),
            ("mrec", "load", 1),
            ("interstitial", "load", 16),
            ("interstitial", "show", 5),
            ("rewarded", "load", 16),
            ("rewarded", "show", 5),
        ]

        executeSteps(steps, at: 0, tabVC: tabVC)
    }

    private static func executeSteps(_ steps: [(format: String, action: String, delay: TimeInterval)],
                                     at index: Int,
                                     tabVC: AdDemoTabViewController) {
        guard index < steps.count else {
            DemoAppLogger.sharedInstance.logMessage("test-all sequence complete")
            return
        }

        let step = steps[index]

        guard let tabIdx = tabIndex(for: step.format),
              tabIdx >= 0,
              tabIdx < tabVC.viewControllers?.count ?? 0 else {
            executeSteps(steps, at: index + 1, tabVC: tabVC)
            return
        }

        tabVC.selectTab(at: tabIdx)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let navVC = tabVC.selectedViewController as? UINavigationController,
               let adVC = navVC.viewControllers.first,
               let sel = selector(for: step.format, action: step.action),
               adVC.responds(to: sel) {
                adVC.perform(sel)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                executeSteps(steps, at: index + 1, tabVC: tabVC)
            }
        }
    }

    // MARK: - Tab Resolution

    private static func tabIndex(for format: String) -> Int? {
        let map: [String: Int] = [
            "banner": 1,
            "mrec": 4,
            "interstitial": 2,
            "rewarded": 3,
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
        let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })

        if let tabVC = window?.rootViewController as? AdDemoTabViewController {
            return tabVC
        }
        if let navVC = window?.rootViewController as? UINavigationController,
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
