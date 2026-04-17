import UIKit

#if canImport(CloudXTestHarness)
import CloudXTestHarness
import CloudXCore

private let kSDKInitTimeout: TimeInterval = 30.0

enum DeepLinkRouter {

    fileprivate static let classNameMap: [String: String] = [
        "banner":                "BannerViewController",
        "mrec":                  "MRECViewController",
        "interstitial":          "InterstitialViewController",
        "rewarded":              "RewardedViewController",
        "native":                "NativeMenuViewController",
    ]

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
        let contentVC = vcAtTabIndex(tabIndex, in: tabVC)

        if format == "native" {
            guard let navVC = contentVC?.navigationController else {
                logMessage("Native tab has no UINavigationController — cannot push NativeViewController")
                return nil
            }
            let nativeVC = NativeViewController()
            navVC.pushViewController(nativeVC, animated: false)
            return nativeVC
        }

        return contentVC
    }

    func navigateToInit() -> UIViewController? {
        guard let tabVC = resolveTabViewController() else { return nil }
        tabVC.selectTab(at: 0)
        return vcAtTabIndex(0, in: tabVC)
    }

    // MARK: - Format Configuration

    func supportedFormats() -> [String] {
        ["banner", "mrec", "interstitial", "rewarded", "native"]
    }

    func isFullscreenFormat(_ format: String) -> Bool {
        format == "interstitial" || format == "rewarded"
    }

    func loadSelector(forFormat format: String) -> Selector? {
        switch format {
        case "banner":                return NSSelectorFromString("loadBannerAd")
        case "mrec":                  return NSSelectorFromString("loadMRECAd")
        case "interstitial":          return NSSelectorFromString("loadInterstitialAd")
        case "rewarded":              return NSSelectorFromString("loadRewardedAd")
        case "native":                return NSSelectorFromString("loadNativeAd")
        default:                      return nil
        }
    }

    func showSelector(forFormat format: String) -> Selector? {
        switch format {
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

    // MARK: - Settings Mutation (CLXTestHarnessApp optional)

    private static func mutationError(_ reason: String) -> NSError {
        NSError(domain: "CLXDemoDeepLinkRouter",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: reason])
    }

    func applySettingsMutation(_ mutationId: String,
                                params: [AnyHashable: Any]) throws {
        let defaults = UserDefaults.standard
        let core = CloudXCore.shared()

        switch mutationId {
        case "gdpr_applies":
            let applies = params["applies"] as? NSNumber ?? NSNumber(value: true)
            let consent = (params["consent"] as? String) ?? "CPabc"
            defaults.set(applies, forKey: "IABTCF_gdprApplies")
            defaults.set(consent, forKey: "IABTCF_TCString")
            CloudXCore.setHasUserConsent(NSNumber(value: true))

        case "us_privacy":
            let value = (params["value"] as? String) ?? "1YNN"
            defaults.set(value, forKey: "IABUSPrivacy_String")

        case "hashed_user_id":
            guard let value = params["value"] as? String, !value.isEmpty else {
                throw Adapter.mutationError("hashed_user_id requires non-empty value")
            }
            core.setHashedUserID(value)

        case "user_kv_add":
            guard let key = params["key"] as? String,
                  let value = params["value"] as? String else {
                throw Adapter.mutationError("user_kv_add requires string key and value")
            }
            core.setUserKeyValue(key, value: value)

        case "app_kv_add":
            guard let key = params["key"] as? String,
                  let value = params["value"] as? String else {
                throw Adapter.mutationError("app_kv_add requires string key and value")
            }
            core.setAppKeyValue(key, value: value)

        case "clear_all_kvs":
            core.clearAllKeyValues()

        case "user_targeting_off":
            // No first-class API yet; clear user KVs as the observable equivalent.
            core.clearAllKeyValues()

        case "hi_roi_targeting_signals":
            let userKVs = (params["user"] as? [String: String]) ?? [
                "ltv_bucket": "high",
                "retention_d7": "true",
            ]
            let appKVs = (params["app"] as? [String: String]) ?? [
                "content_rating": "E",
                "monetization_tier": "premium",
            ]
            for (key, value) in userKVs { core.setUserKeyValue(key, value: value) }
            for (key, value) in appKVs { core.setAppKeyValue(key, value: value) }

        default:
            throw Adapter.mutationError("unsupported mutationId: \(mutationId)")
        }
    }

    func verifyCleanState() throws {
        let privacy = CLXManualPrivacyState.sharedInstance()
        if privacy.hasUserConsent != nil {
            throw Adapter.mutationError("CLXManualPrivacyState.hasUserConsent is set")
        }
        if privacy.doNotSell != nil {
            throw Adapter.mutationError("CLXManualPrivacyState.doNotSell is set")
        }

        let kvs = CLXKeyValueState.shared()
        if let hashed = kvs.hashedUserId, !hashed.isEmpty {
            throw Adapter.mutationError("CLXKeyValueState.hashedUserId is set")
        }
        if kvs.userKeyValues.count > 0 {
            throw Adapter.mutationError("CLXKeyValueState.userKeyValues is non-empty")
        }
        if kvs.appKeyValues.count > 0 {
            throw Adapter.mutationError("CLXKeyValueState.appKeyValues is non-empty")
        }

        let iabKeys = ["IABTCF_gdprApplies", "IABTCF_TCString", "IABUSPrivacy_String"]
        let defaults = UserDefaults.standard
        for key in iabKeys where defaults.object(forKey: key) != nil {
            throw Adapter.mutationError("UserDefaults \(key) is set")
        }
    }
}

#else

// CloudXTestHarness not available — provide no-op stubs so the app compiles without the QA pod.
enum DeepLinkRouter {
    static func setup() {}
    static func handleLaunchArguments() {}
    @discardableResult
    static func handleURL(_ url: URL) -> Bool { false }
}

#endif
