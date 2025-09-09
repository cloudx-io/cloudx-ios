//
//  AdapterRewarded.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import UIKit

/// Protocol for rewarded adapters.
public protocol AdapterRewarded: Destroyable, StatusCheck {
    /// Delegate for the adapter, used to notify about ad events.
    var delegate: AdapterRewardedDelegate? { get set }
    
    /// SDK version of the adapter.
    var sdkVersion: String { get }
    
    /// Network name of the adapter. F.e. "AdMob", "Facebook", etc.
    var network: String { get }
    
    /// Ad id from bid response.
    var bidID: String { get }
    
    /// Loads the rewarded adapter.
    func load()
    
    /// Shows the rewarded adapter.
    /// - Parameter viewController: view controller where the interstitial will be displayed
    func show(from viewController: UIViewController)
}

/// Delegate for the rewarded adapter
public protocol AdapterRewardedDelegate: AnyObject {
    
    /// Called when the adapter has loaded the rewarded.
    /// - Parameter rewarded: the rewarded that was loaded
    func didLoad(rewarded: AdapterRewarded)
    
    /// Called when the adapter failed to load the rewarded.
    /// - Parameter rewarded: the rewarded that failed to load
    /// - Parameter error: the error that caused the failure
    func didFailToLoad(rewarded: AdapterRewarded, error: Error)
    
    /// Called when the adapter has shown the rewarded.
    /// - Parameter rewarded: the rewarded that was shown
    func didShow(rewarded: AdapterRewarded)
    
    /// Called when the adapter has tracked impression.
    /// - Parameter rewarded: the rewarded that was shown
    func impression(rewarded: AdapterRewarded)
    
    /// Called when the adapter has closed the rewarded.
    /// - Parameter rewarded: the rewarded that was closed
    func didClose(rewarded: AdapterRewarded)
    
    /// Called when the adapter has failed to show the rewarded.
    /// - Parameter rewarded: the rewarded that failed to show
    /// - Parameter error: error that caused the failure
    func didFailToShow(rewarded: AdapterRewarded, error: Error)
    
    /// Called when the adapter has clicked the rewarded.
    /// - Parameter rewarded: the rewarded that was clicked
    func click(rewarded: AdapterRewarded)//clickType: ClickType = ClickType.Main
    
    /// Called when the adapter has expired the rewarded.
    /// - Parameter rewarded: the rewarded that was expired
    func expired(rewarded: AdapterRewarded)
    
    /// Called when the adapter has rewarded the user.
    /// - Parameter rewarded: the rewarded that was rewarded
    func userReward(rewarded: AdapterRewarded)
    
}

/// Factory for rewarded adapters
public protocol AdapterRewardedFactory: AdFactory, Instanciable {
    
    /// Creates a new instance of `AdapterRewarded` with the given parameters.
    /// - Parameters:
    ///   - adId:  id of ad from bid response
    ///   - bidId: bid id from bid response
    ///   - adm: ad markup with data for rendering
    ///   - delegate: delegate for the adapter
    /// - Returns: new instance of `AdapterRewarded`
    func create(
        adId: String,
        bidId: String,
        adm: String,
        extras: [String : String],
        delegate: AdapterRewardedDelegate
    ) -> AdapterRewarded?
    
}

// MARK: - Objective-C Compatibility

/// Objective-C compatible protocol for rewarded adapters.
/// Mirrors AdapterRewarded but uses Objective-C types.
@objc public protocol AdapterRewardedObjC: NSObjectProtocol, StatusCheck {
    /// Delegate for the adapter, used to notify about ad events.
    @objc var delegate: AdapterRewardedDelegateObjC? { get set }
    /// Flag to indicate if the rewarded loading timed out.
    @objc var timeout: Bool { get set }
    /// SDK version of the adapter.
    @objc var sdkVersion: NSString { get }
    /// Whether the ad is ready to be shown.
    @objc var isReady: Bool { get }
    /// Loads the rewarded ad.
    @objc func load()
    /// Shows the rewarded ad from the given view controller.
    @objc func showFromViewController(_ viewController: UIViewController)
    /// Destroys the rewarded ad.
    @objc func destroy()
}

/// Objective-C compatible delegate for the rewarded adapter.
/// Mirrors AdapterRewardedDelegate but uses Objective-C types.
@objc public protocol AdapterRewardedDelegateObjC: NSObjectProtocol {
    /// Called when the adapter has loaded the rewarded ad.
    /// - Parameter rewarded: the rewarded ad that was loaded.
    @objc optional func didLoadWithRewarded(_ rewarded: NSObject)
    /// Called when the adapter failed to load the rewarded ad.
    /// - Parameters:
    ///   - rewarded: rewarded ad that failed to load
    ///   - error: error that caused the failure
    @objc optional func failToLoadWithRewarded(_ rewarded: NSObject?, error: NSError?)
    /// Called when the adapter has shown the rewarded ad.
    /// - Parameter rewarded: the rewarded ad that was shown
    @objc optional func didShowWithRewarded(_ rewarded: NSObject)
    /// Called when the rewarded ad was clicked.
    /// - Parameter rewarded: the rewarded ad that was clicked
    @objc optional func didClickWithRewarded(_ rewarded: NSObject)
    /// Called when the rewarded ad was closed.
    /// - Parameter rewarded: the rewarded ad that was closed
    @objc optional func didCloseWithRewarded(_ rewarded: NSObject)
    /// Called when the rewarded ad will close.
    /// - Parameter rewarded: the rewarded ad that will close
    @objc optional func willCloseWithRewarded(_ rewarded: NSObject)
    /// Called when the rewarded ad video completed.
    /// - Parameter rewarded: the rewarded ad that completed
    @objc optional func didReceiveRewardWithRewarded(_ rewarded: NSObject)
}

/// Objective-C compatible factory for creating rewarded adapters.
/// Mirrors AdapterRewardedFactory but uses Objective-C types.
@objc public protocol AdapterRewardedFactoryObjC: NSObjectProtocol, Instantiable {
    @objc static func createInstance() -> AnyObject // For dynamic instantiation

    /// Creates a new instance of AdapterRewardedObjC with the given parameters.
    /// - Important: This method must be called on the main thread.
    /// - Parameters:
    ///   - viewController: viewController where the rewarded ad will be displayed
    ///   - adId: id of ad from bid response
    ///   - bidId: bid id from bid response
    ///   - adm: ad markup with data for rendering
    ///   - delegate: delegate for the adapter
    /// - Returns: AdapterRewardedObjC instance
    @objc func createWithViewController(_ viewController: UIViewController,
                                      adId: NSString,
                                      bidId: NSString,
                                      adm: NSString,
                                      delegate: AdapterRewardedDelegateObjC?) -> AdapterRewardedObjC?
}

// MARK: - Type-Erased Wrappers for Rewarded Factory
protocol UnifiedAdapterRewardedFactory {
    func createRewarded(
        adId: String,
        bidId: String,
        adm: String,
        extras: [String: String],
        delegate: AdapterRewardedDelegate
    ) -> AdapterRewarded?
}

struct SwiftUnifiedAdapterRewardedFactory: UnifiedAdapterRewardedFactory {
    let factory: AdapterRewardedFactory
    func createRewarded(
        adId: String,
        bidId: String,
        adm: String,
        extras: [String: String],
        delegate: AdapterRewardedDelegate
    ) -> AdapterRewarded? {
        return factory.create(
            adId: adId,
            bidId: bidId,
            adm: adm,
            extras: extras,
            delegate: delegate
        )
    }
}

// MARK: - Swift <-> ObjC Delegate Bridge

final class AdapterRewardedDelegateBridge: NSObject, AdapterRewardedDelegateObjC {
    let swiftDelegate: AdapterRewardedDelegate
    private weak var bridge: AdapterRewardedObjCBridge?

    init(swiftDelegate: AdapterRewardedDelegate) {
        self.swiftDelegate = swiftDelegate
        super.init()
    }

    func setBridge(_ bridge: AdapterRewardedObjCBridge) {
        self.bridge = bridge
    }

    func didLoadWithRewarded(_ rewarded: NSObject) {
        print("[AdapterRewardedDelegateBridge] Ad loaded")
        if let bridge = bridge {
            bridge.loadedAdInstance = rewarded
            bridge.isLoading = false
            print("[AdapterRewardedDelegateBridge] Stored loaded ad instance")
            swiftDelegate.didLoad(rewarded: bridge)
        }
    }

    func failToLoadWithRewarded(_ rewarded: NSObject?, error: NSError?) {
        print("[AdapterRewardedDelegateBridge] Ad failed to load")
        if let bridge = bridge {
            bridge.isLoading = false
            swiftDelegate.didFailToLoad(rewarded: bridge, error: error ?? NSError(domain: "CloudX", code: -1))
        }
    }

    func didShowWithRewarded(_ rewarded: NSObject) {
        if let bridge = bridge {
            swiftDelegate.didShow(rewarded: bridge)
        }
    }

    func didClickWithRewarded(_ rewarded: NSObject) {
        if let bridge = bridge {
            swiftDelegate.click(rewarded: bridge)
        }
    }

    func didCloseWithRewarded(_ rewarded: NSObject) {
        if let bridge = bridge {
            swiftDelegate.didClose(rewarded: bridge)
        }
    }

    func willCloseWithRewarded(_ rewarded: NSObject) {
        // Optional: implement if needed
    }

    func didReceiveRewardWithRewarded(_ rewarded: NSObject) {
        if let bridge = bridge {
            swiftDelegate.userReward(rewarded: bridge)
        }
    }
}

// MARK: - Swift <-> ObjC Instance Bridge

/// Bridge class to wrap an AdapterRewardedObjC and expose it as AdapterRewarded to Swift code.
final class AdapterRewardedObjCBridge: AdapterRewarded {
    private let objcInstance: AdapterRewardedObjC
    private let timeoutInterval: TimeInterval = 10.0
    private var timeoutTimer: Timer?
    private let bidId: String
    internal var loadedAdInstance: AnyObject?
    internal var isLoading: Bool = false
    private var delegateBridge: AdapterRewardedDelegateBridge?

    init(_ objcInstance: AdapterRewardedObjC) {
        self.objcInstance = objcInstance
        // Get bidId from the instance
        if let bidID = (objcInstance as? NSObject)?.value(forKey: "bidID") as? String {
            self.bidId = bidID
        } else {
            self.bidId = "unknown"
        }
        print("[AdapterRewardedObjCBridge] Initialized with bidId: \(bidId)")
    }

    var delegate: AdapterRewardedDelegate? {
        get { delegateBridge?.swiftDelegate }
        set {
            if let newValue = newValue {
                print("[AdapterRewardedObjCBridge] Setting delegate")
                delegateBridge = AdapterRewardedDelegateBridge(swiftDelegate: newValue)
                delegateBridge?.setBridge(self)
                objcInstance.delegate = delegateBridge
            } else {
                print("[AdapterRewardedObjCBridge] Removing delegate")
                delegateBridge = nil
                objcInstance.delegate = nil
            }
        }
    }

    var sdkVersion: String {
        return objcInstance.sdkVersion as String
    }

    var network: String {
        return (objcInstance as? NSObject)?.value(forKey: "network") as? String ?? ""
    }

    var bidID: String {
        return bidId
    }

    func load() {
        print("[AdapterRewardedObjCBridge] Starting to load ad")
        isLoading = true
        loadedAdInstance = nil

        // Cancel any existing timeout timer
        timeoutTimer?.invalidate()

        // Create new timeout timer
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("[AdapterRewardedObjCBridge] Ad loading timed out after \(self.timeoutInterval) seconds")
            self.objcInstance.timeout = true
            self.isLoading = false
            self.delegate?.didFailToLoad(rewarded: self, error: NSError(domain: "CloudX", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ad loading timed out after \(self.timeoutInterval) seconds"]))
        }

        objcInstance.load()
    }

    func show(from viewController: UIViewController) {
        objcInstance.showFromViewController(viewController)
    }

    func destroy() {
        objcInstance.destroy()
    }

    var isReady: Bool {
        print("[AdapterRewardedObjCBridge] Checking isReady state")

        // First check if we have a loaded ad instance
        if let loadedAd = loadedAdInstance {
            print("[AdapterRewardedObjCBridge] Found loaded ad instance")
            if loadedAd.responds(to: Selector(("isReady"))) {
                let objcReady = loadedAd.value(forKey: "isReady") as? Bool ?? false
                print("[AdapterRewardedObjCBridge] Loaded ad instance isReady: \(objcReady)")
                if objcReady && !isLoading {
                    timeoutTimer?.invalidate()
                    timeoutTimer = nil
                    return true
                }
            }
        }

        // Fallback to direct protocol call
        let ready = objcInstance.isReady && !isLoading
        print("[AdapterRewardedObjCBridge] Direct protocol call isReady: \(ready)")
        if ready {
            timeoutTimer?.invalidate()
            timeoutTimer = nil
        }
        return ready
    }
}

struct ObjCUnifiedAdapterRewardedFactory: UnifiedAdapterRewardedFactory {
    let factory: AdapterRewardedFactoryObjC

    func createRewarded(
        adId: String,
        bidId: String,
        adm: String,
        extras: [String: String],
        delegate: AdapterRewardedDelegate
    ) -> AdapterRewarded? {
        var result: AdapterRewarded?
        let objcDelegate = AdapterRewardedDelegateBridge(swiftDelegate: delegate)

        let createInstance = {
            // Create a temporary view controller for initialization
            let tempVC = UIViewController()
            let objcInstance = factory.createWithViewController(
                tempVC,
                adId: adId as NSString,
                bidId: bidId as NSString,
                adm: adm as NSString,
                delegate: objcDelegate
            )

            if let objcInstance = objcInstance as? AdapterRewardedObjC {
                result = AdapterRewardedObjCBridge(objcInstance)
            }
        }

        // Always create the instance on the main thread, but avoid deadlock if already on main thread
        if Thread.isMainThread {
            createInstance()
        } else {
            DispatchQueue.main.sync {
                createInstance()
            }
        }

        return result
    }
}
