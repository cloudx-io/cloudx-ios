//
//  CloudXBaseAd.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import Foundation

/// Base protocol for all ad types.
@objc public protocol CloudXAd: Destroyable, StatusCheck {
    /// Starts loading ad
    func load()
}

/// Base protocol for all ad delegates.
@objc public protocol BaseAdDelegate: AnyObject {
    
    /// Called when ad is loaded.
    /// - Parameter ad: ad that was loaded
    func didLoad(ad: CloudXAd)
    
    /// Called when ad fails to load with error.
    /// - Parameters:
    ///   - ad: ad that failed to load
    ///   - error: error that caused the failure
    func failToLoad(ad: CloudXAd, with error: Error)
    
    /// Called when ad is shown.
    /// - Parameter ad: ad that was shown
    func didShow(ad: CloudXAd)
    
    /// Called when ad fails to show.
    /// - Parameters:
    ///   - ad: ad that failed to show
    ///   - error: error that caused the failure
    func failToShow(ad: CloudXAd, with error: Error)
    
    /// Called when ad is closed.
    /// - Parameter ad: ad that was closed
    func didHide(ad: CloudXAd)
    
    /// Called when ad is clicked.
    /// - Parameter ad: ad that was clicked
    func didClick(on ad: CloudXAd)
    
    /// Called when ad impression is detected.
    /// - Parameter ad: ad that was shown
    func impression(on ad: CloudXAd)
    
    /// Called when ad impression is detected.
    /// - Parameter ad: ad that was shown
    func closedByUserAction(on ad: CloudXAd)
}

/// Protocol for Interstitial ad delegates.
@objc public protocol CloudXInterstitialDelegate: BaseAdDelegate {}

/// Protocol for Rewarded ad delegates.
@objc public protocol CloudXRewardedDelegate: BaseAdDelegate {
    
    /// Called when user is rewarded.
    /// - Parameter ad: ad that was rewarded
    @objc func userRewarded(ad: CloudXAd)
    
    /// Called when rewarded video started.
    /// - Parameter ad: ad that was started
    @objc func rewardedVideoStarted(ad: CloudXAd)
    
    /// Called when rewarded video completed.
    /// - Parameter ad: ad that was completed
    @objc func rewardedVideoCompleted(ad: CloudXAd)
}

/// Protocol for Banner ad delegates.
@objc public protocol CloudXBannerDelegate: BaseAdDelegate {}

/// Protocol for Native ad delegates.
@objc public protocol CloudXNativeDelegate: BaseAdDelegate {}
