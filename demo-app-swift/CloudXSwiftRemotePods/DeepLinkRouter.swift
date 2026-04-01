import UIKit
import CloudXTestHarness

/// App-specific adapter that bridges the demo app to CLXTestHarnessEngine.
///
/// Implements CLXTestHarnessApp to provide app-specific details
/// (tab navigation, format-to-selector mapping, ad state queries, logging).
/// All generic automation logic (dismiss detection, click testing, polling,
/// synthetic UITouch) lives in the CloudXTestHarness pod.
private let kSDKInitTimeout: TimeInterval = 30.0

enum DeepLinkRouter {

    fileprivate static let classNameMap: [String: String] = [
        "banner":                "BannerViewController",
        "banner_deferred":       "BannerViewController",
        "mrec":                  "MRECViewController",
        "interstitial":          "InterstitialViewController",
        "rewarded":              "RewardedViewController",
    ]

    /// Register the adapter and forward launch arguments.
    static func setup() {
        CLXTestHarnessEngine.register(Adapter.shared)
    }

    static func handleLaunchArguments() {
        setup()
        CLXTestHarnessEngine.handleLaunchArguments()
    }

    @discardableResult
    static func handleURL(_ url: URL) -> Bool {
        setup()
        return CLXTestHarnessEngine.handle(url)
    }
}

// MARK: - CLXTestHarnessApp Adapter

private final class Adapter: NSObject, CLXTestHarnessApp {

    static let shared = Adapter()

    // MARK: - Navigation

    func navigate(toFormat format: String) -> UIViewController? {
        guard let tabVC = resolveTabViewController(),
              let tabIndex = tabIndex(for: format, in: tabVC) else { return nil }
        tabVC.selectTab(at: tabIndex)
        return vcAtTabIndex(tabIndex, in: tabVC)
    }

    func navigateToInit() -> UIViewController? {
        guard let tabVC = resolveTabViewController() else { return nil }
        tabVC.selectTab(at: 0)
        return vcAtTabIndex(0, in: tabVC)
    }

    // MARK: - Format Configuration

    func supportedFormats() -> [String] {
        ["banner", "banner_deferred", "mrec", "interstitial", "rewarded"]
    }

    func isFullscreenFormat(_ format: String) -> Bool {
        format == "interstitial" || format == "rewarded"
    }

    func loadSelector(forFormat format: String) -> Selector? {
        switch format {
        case "banner":                return NSSelectorFromString("loadBannerAd")
        case "banner_deferred":       return NSSelectorFromString("loadBannerDeferred")
        case "mrec":                  return NSSelectorFromString("loadMRECAd")
        case "interstitial":          return NSSelectorFromString("loadInterstitialAd")
        case "rewarded":              return NSSelectorFromString("loadRewardedAd")
        default:                      return nil
        }
    }

    func showSelector(forFormat format: String) -> Selector? {
        switch format {
        case "banner_deferred":       return NSSelectorFromString("showDeferredBanner")
        case "interstitial":          return NSSelectorFromString("showInterstitialAd")
        case "rewarded":              return NSSelectorFromString("showRewardedAd")
        default:                      return nil
        }
    }

    // MARK: - Ad State

    func hasReceivedCallback(_ event: CLXTestCallback, forVC vc: UIViewController) -> Bool {
        guard let stateVC = vc as? (UIViewController & AdStateManaging) else { return false }
        // CLXTestCallback bit positions match AdCallbackEvent bit positions
        return stateVC.receivedCallbacks.rawValue & event.rawValue != 0
    }

    func isLoading(forVC vc: UIViewController) -> Bool {
        guard let stateVC = vc as? (UIViewController & AdStateManaging) else { return false }
        return stateVC.isLoading
    }

    func didLoadSuccessfully(forVC vc: UIViewController) -> Bool {
        guard let baseVC = vc as? BaseAdViewController else { return false }
        let text = baseVC.statusLabel.text ?? ""
        let hasFailure = text.contains("Failed") || text.contains("Error") ||
                         text.contains("No Ad") || text.contains("No Fill")
        let isGreen = baseVC.statusIndicator.backgroundColor == .systemGreen
        return isGreen && !hasFailure
    }

    func adViewForClickTesting(onVC vc: UIViewController) -> UIView? {
        (vc as? AdStateManaging)?.adViewForClickTesting()
    }

    // MARK: - SDK Init

    func triggerInit(withEnvironment env: String, completion: @escaping (Bool) -> Void) {
        guard let initVC = navigateToInit() else {
            completion(false)
            return
        }

        guard let initSel = resolveInitSelector(for: initVC, environment: env) else {
            logMessage("Init VC does not respond to any init selector — aborting")
            completion(false)
            return
        }

        var completed = false
        var observer: NSObjectProtocol?

        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("cloudXSDKInitialized"),
            object: nil,
            queue: .main
        ) { _ in
            guard !completed else { return }
            completed = true
            if let obs = observer { NotificationCenter.default.removeObserver(obs) }
            completion(true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            initVC.perform(initSel)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + kSDKInitTimeout) {
            guard !completed else { return }
            completed = true
            if let obs = observer { NotificationCenter.default.removeObserver(obs) }
            completion(false)
        }
    }

    // MARK: - Logging

    func logMessage(_ message: String) {
        DemoAppLogger.sharedInstance.logMessage(message)
    }

    // MARK: - Tab & VC Resolution (Private)

    private func resolveTabViewController() -> AdDemoTabViewController? {
        guard let window = keyWindow else { return nil }
        if let tabVC = window.rootViewController as? AdDemoTabViewController {
            return tabVC
        }
        if let navVC = window.rootViewController as? UINavigationController,
           let tabVC = navVC.topViewController as? AdDemoTabViewController {
            return tabVC
        }
        logMessage("Could not resolve AdDemoTabViewController for deep link")
        return nil
    }

    private func tabIndex(for format: String, in tabVC: AdDemoTabViewController) -> Int? {
        guard let targetClassName = DeepLinkRouter.classNameMap[format],
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
        return nil
    }

    private func vcAtTabIndex(_ tabIndex: Int, in tabVC: AdDemoTabViewController) -> UIViewController? {
        guard tabIndex >= 0, tabIndex < (tabVC.viewControllers?.count ?? 0) else { return nil }

        let vc = tabVC.viewControllers![tabIndex]
        if let navVC = vc as? UINavigationController, let root = navVC.viewControllers.first {
            return root
        } else {
            // "More" tab fallback
            if tabVC.selectedIndex == tabIndex {
                let top = tabVC.moreNavigationController.topViewController
                if let navVC = top as? UINavigationController, let root = navVC.viewControllers.first {
                    return root
                }
                if let top = top { return top }
            }
            return vc
        }
    }

    private func resolveInitSelector(for vc: UIViewController, environment env: String) -> Selector? {
        let envSel: Selector
        switch env {
        case "local":   envSel = NSSelectorFromString("initializeWithLocalEnvironment")
        case "staging": envSel = NSSelectorFromString("initializeWithStagingEnvironment")
        case "dev":     envSel = NSSelectorFromString("initializeWithDevEnvironment")
        default:        envSel = NSSelectorFromString("initializeWithProductionEnvironment")
        }
        if vc.responds(to: envSel) { return envSel }
        let genericSel = NSSelectorFromString("initializeSDK")
        if vc.responds(to: genericSel) { return genericSel }
        return nil
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
