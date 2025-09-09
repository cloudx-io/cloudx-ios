//
//  AdapterBanner.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import UIKit

/// Protocol for banner adapters.
public protocol AdapterBanner: Destroyable {
    /// Delegate for the adapter, used to notify about ad events.
    var delegate: AdapterBannerDelegate? { get set }
    
    /// Flag to indicate if the banner loading timed out.
    var timeout: Bool { get set }
    
    /// View containing the banner.
    var bannerView: UIView? { get }
    
    /// SDK version of the adapter.
    var sdkVersion: String { get }
    
    /// Loads the banner.
    func load()
    
}

/// Delegate for the banner adapter.
public protocol AdapterBannerDelegate: AnyObject {
    /// Called when the adapter has loaded the banner.
    /// - Parameter banner: the banner that was loaded.
    func didLoad(banner: AdapterBanner)
    
    /// Called when the adapter failed to load the banner.
    /// - Parameters:
    ///   - banner: banner that failed to load
    ///   - error: error that caused the failure
    func failToLoad(banner: AdapterBanner?, error: Error?)
    
    /// Called when the adapter has shown the banner.
    /// - Parameter banner: the banner that was shown
    func didShow(banner: AdapterBanner)
    
    /// Called when the adapter has tracked impression.
    /// - Parameter banner: the banner that was shown
    func impression(banner: AdapterBanner)
    
    ///  Called when the adapter has tracked click.
    /// - Parameter banner: banner that was clicked
    func click(banner: AdapterBanner)
    
    /// Called when the banner was closed by user action.
    /// - Parameter banner: the banner that was closed
    func closedByUserAction(banner: AdapterBanner)
}

/// Factory for creating banner adapters
public protocol AdapterBannerFactory: AdFactory, Instanciable {
    
    @MainActor
    /// Creates a new instance of `AdapterBanner` with the given parameters
    /// - Parameters:
    ///   - viewController: viewController where the banner will be displayed
    ///   - type: type of the banner (mrec, banner, etc.)
    ///   - adId: id of ad from bid response
    ///   - bidId: bid id from bid response
    ///   - adm: ad markup with data for rendering
    ///   - delegate: delegate for the adapter
    /// - Returns: AdapterBanner instance
    func create(
        viewController: UIViewController,
        type: CloudXBannerType,
        adId: String,
        bidId: String,
        adm: String,
        hasClosedButton: Bool,
        extras: [String : String],
        delegate: AdapterBannerDelegate
    ) -> AdapterBanner?
    
}
