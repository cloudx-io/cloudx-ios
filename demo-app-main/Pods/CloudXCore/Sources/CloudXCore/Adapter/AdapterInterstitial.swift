//
//  AdapterInterstitial.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import UIKit

/// Protocol for interstitial adapters. Interstitial adapters are responsible for loading and showing interstitial ads.
public protocol AdapterInterstitial: Destroyable, StatusCheck {
    /// Delegate for the adapter, used to notify about ad events.
    var delegate: AdapterInterstitialDelegate? { get set }
    
    /// SDK version of the adapter.
    var sdkVersion: String { get }
    
    /// Network name of the adapter. F.e. "AdMob", "Facebook", etc.
    var network: String { get }
    
    /// Ad id from bid response.
    var bidID: String { get }
    
    /// Loads the adapter interstitial.
    func load()
    
    /// Shows the adapter interstitial.
    /// - Parameter viewController: view controller where the interstitial will be displayed
    func show(from viewController: UIViewController)
}

/// Delegate for the interstitial adapter.
public protocol AdapterInterstitialDelegate: AnyObject {
    
    /// Called when the adapter has loaded the interstitial.
    /// - Parameter interstitial: the interstitial that was loaded
    func didLoad(interstitial: AdapterInterstitial)
    
    /// Called when the adapter failed to load the interstitial.
    /// - Parameters:
    ///   - interstitial: the interstitial that failed to load
    ///   - error: the error that caused the failure
    func didFailToLoad(interstitial: AdapterInterstitial, error: Error)
    
    /// Called when the adapter has shown the interstitial.
    /// - Parameter interstitial: the interstitial that was shown
    func didShow(interstitial: AdapterInterstitial)
    
    /// Called when the adapter has failed to show the interstitial.
    /// - Parameters:
    ///   - interstitial: the interstitial that failed to show
    ///   - error: error that caused the failure
    func didFailToShow(interstitial: AdapterInterstitial, error: Error)
    
    /// Called when the adapter has tracked impression.
    /// - Parameter interstitial: the interstitial that was shown
    func impression(interstitial: AdapterInterstitial)
    
    /// Called when the adapter has closed the interstitial.
    /// - Parameter interstitial: the interstitial that was closed
    func didClose(interstitial: AdapterInterstitial)
    
    /// Called when the adapter has tracked click.
    /// - Parameter interstitial: interstitial that was clicked
    func click(interstitial: AdapterInterstitial)//clickType: ClickType = ClickType.Main
    
    /// Called when the adapter has expired the interstitial.
    /// - Parameter interstitial: interstitial that was expired
    func expired(interstitial: AdapterInterstitial)
    
}

/// Factory for creating interstitial adapters.
public protocol AdapterInterstitialFactory: AdFactory, Instanciable {
    
    /// Creates a new instance of `AdapterInterstitial` with the given parameters.
    /// - Parameters:
    ///   - adId: id of ad from bid response
    ///   - bidId: bid id from bid response
    ///   - adm: ad markup with data for rendering
    ///   - delegate: delegate for the adapter
    /// - Returns: new instance of `AdapterInterstitial`
    func create(
        adId: String,
        bidId: String,
        adm: String,
        extras: [String : String],
        delegate: AdapterInterstitialDelegate
    ) -> AdapterInterstitial?
    
}
