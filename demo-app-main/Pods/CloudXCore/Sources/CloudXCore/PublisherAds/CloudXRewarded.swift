//
//  CloudXRewarded.swift
//  CloudXCore
//
//  Created by Xenoss on 04.06.2025.
//


import UIKit

/// Bridge class to wrap a CloudXRewardedInterstitial and expose it to Objective-C code.
@objc public final class CloudXRewardedObjCBridge: NSObject, CloudXRewardedDelegate {
    private let swiftInstance: CloudXRewardedInterstitial
    @objc public var timeout: Bool = false
    private var isLoading: Bool = false
    private var loadStartTime: Date?
    private let placement: String
    private var loadedAdInstance: AnyObject?

    // Static cache to maintain instances
    private static var instanceCache: [String: CloudXRewardedObjCBridge] = [:]

    init(_ swiftInstance: CloudXRewardedInterstitial, placement: String) {
        self.swiftInstance = swiftInstance
        self.placement = placement
        super.init()
        print("[CloudXRewardedObjCBridge] Initialized with instance: \(type(of: swiftInstance))")
        print("[CloudXRewardedObjCBridge] Instance address: \(Unmanaged.passUnretained(self).toOpaque())")
        print("[CloudXRewardedObjCBridge] Swift instance address: \(Unmanaged.passUnretained(swiftInstance as AnyObject).toOpaque())")
        print("[CloudXRewardedObjCBridge] Placement: \(placement)")

        // Set up delegate to handle loading state
        if let publisherAd = swiftInstance as? PublisherFullscreenAd {
            publisherAd.rewardedDelegate = self
        }
    }

    deinit {
        print("[CloudXRewardedObjCBridge] Deinitializing instance for placement: \(placement)")
        // Remove from cache when deallocated
        Self.instanceCache.removeValue(forKey: placement)
    }

    // Static method to get or create an instance
    static func getOrCreateInstance(for swiftInstance: CloudXRewardedInterstitial, placement: String) -> CloudXRewardedObjCBridge {
        if let existingInstance = instanceCache[placement] {
            print("[CloudXRewardedObjCBridge] Reusing existing instance for placement: \(placement)")
            return existingInstance
        }

        print("[CloudXRewardedObjCBridge] Creating new instance for placement: \(placement)")
        let instance = CloudXRewardedObjCBridge(swiftInstance, placement: placement)
        instanceCache[placement] = instance
        return instance
    }

    @objc public var isReady: Bool {
        if let publisherAd = swiftInstance as? PublisherFullscreenAd {
            // First check if we have a loaded ad instance
            if let loadedAd = loadedAdInstance {
                let ptr = Unmanaged.passUnretained(loadedAd).toOpaque()
                if loadedAd.responds(to: Selector(("isReady"))) {
                    let objcReady = loadedAd.value(forKey: "isReady") as? Bool ?? false
                    print("[CloudXRewardedObjCBridge] Using loaded ad instance: \(ptr), isReady: \(objcReady)")
                    return objcReady && !isLoading
                }
            }

            // Fallback to publisher ad check
            let ready = publisherAd.isReady && !isLoading
            if let startTime = loadStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                print("[CloudXRewardedObjCBridge] isReady check: \(ready) (loading: \(isLoading), elapsed: \(String(format: "%.1f", elapsed))s)")
            } else {
                print("[CloudXRewardedObjCBridge] isReady check: \(ready) (loading: \(isLoading))")
            }
            return ready
        }
        print("[CloudXRewardedObjCBridge] WARNING: Swift instance is not PublisherFullscreenAd")
        return false
    }

    @objc public func load() {
        print("[CloudXRewardedObjCBridge] Starting load")
        isLoading = true
        loadStartTime = Date()
        loadedAdInstance = nil
        swiftInstance.load()

        // Reset loading state after a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }
            if self.isLoading {
                print("[CloudXRewardedObjCBridge] Load timed out after 10 seconds")
                self.isLoading = false
                self.loadStartTime = nil
            }
        }
    }

    @objc public func showFromViewController(_ viewController: UIViewController) {
        print("[CloudXRewardedObjCBridge] Showing from view controller")
        if !isReady {
            print("[CloudXRewardedObjCBridge] WARNING: Attempting to show ad that is not ready")
        }
        swiftInstance.show(from: viewController)
    }

    // MARK: - BaseAdDelegate

    public func didLoad(ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Ad loaded successfully")
        isLoading = false
        loadStartTime = nil

        // Store the loaded ad instance
        if let publisherAd = ad as? PublisherFullscreenAd,
           let objcInstance = publisherAd as? NSObject {
            loadedAdInstance = objcInstance
            print("[CloudXRewardedObjCBridge] Stored loaded ad instance: \(Unmanaged.passUnretained(objcInstance).toOpaque())")
        }
    }

    public func failToLoad(ad: CloudXAd, with error: Error) {
        print("[CloudXRewardedObjCBridge] Ad failed to load: \(error)")
        isLoading = false
        loadStartTime = nil
    }

    public func didShow(ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Ad shown")
    }

    public func failToShow(ad: CloudXAd, with error: Error) {
        print("[CloudXRewardedObjCBridge] Ad failed to show: \(error)")
    }

    public func didHide(ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Ad hidden")
    }

    public func didClick(on ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Ad clicked")
    }

    public func impression(on ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Ad impression")
    }

    public func closedByUserAction(on ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Ad closed by user action")
    }

    // MARK: - CloudXRewardedDelegate

    public func userRewarded(ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] User rewarded")
    }

    public func rewardedVideoStarted(ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Rewarded video started")
    }

    public func rewardedVideoCompleted(ad: CloudXAd) {
        print("[CloudXRewardedObjCBridge] Rewarded video completed")
    }
} 
