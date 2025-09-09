//
//  AdapterNative.swift
//
//
//  Created by bkorda on 01.04.2024.
//

import UIKit

/// Protocol for native ad adapters. Native ad adapters are responsible for loading and showing native ads.
public protocol AdapterNative: Destroyable {
    /// Delegate for the adapter, used to notify about ad events.
    var delegate: AdapterNativeDelegate? { get set }
    /// Flag to indicate if the native loading timed out.
    var timeout: Bool { get set }
    /// View containing the native ad.
    var nativeView: UIView? { get }
    /// SDK version of the adapter.
    var sdkVersion: String { get }
    /// Loads the native ad.
    func load()
    
}

/// Delegate for the native adapter.
public protocol AdapterNativeDelegate: AnyObject {
    
    /// Called when the adapter has loaded the native ad.
    /// - Parameter native: the native ad that was loaded
    func didLoad(native: AdapterNative)
    
    /// Called when the adapter failed to load the native ad.
    /// - Parameters:
    ///   - native: native ad that failed to load
    ///   - error: error that caused the failure
    func failToLoad(native: AdapterNative?, error: Error?)
    
    /// Called when the adapter has shown the native ad.
    /// - Parameter native: the native ad that was shown
    func didShow(native: AdapterNative)
    
    /// Called when the adapter has tracked impression.
    /// - Parameter native: the native ad that was shown
    func impression(native: AdapterNative)
    
    /// Called when the adapter has tracked click.
    /// - Parameter native: native ad that was clicked
    func click(native: AdapterNative)
    
    /// Called when the adapter has tracked close click.
    /// - Parameter native: native ad that was closed
    func close(native: AdapterNative)
    
}

/// Factory for creating native ad adapters.
public protocol AdapterNativeFactory: AdFactory, Instanciable {
    
    @MainActor
    /// Creates a new instance of `AdapterNative` with the given parameters.
    /// - Parameters:
    ///   - viewController: viewController where the native ad will be displayed
    ///   - type: native template type (small, medium)
    ///   - adId: id of ad from bid response
    ///   - bidId: bid id from bid response
    ///   - adm: ad markup with data for rendering
    ///   - extras: adapters extra info
    ///   - delegate: delegate for the adapter
    /// - Returns: AdapterNative instance
    func create(
        viewController: UIViewController,
        type: CloudXNativeTemplate,
        adId: String,
        bidId: String,
        adm: String,
        extras: [String : String],
        delegate: AdapterNativeDelegate
    ) -> AdapterNative?
    
}
