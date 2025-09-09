//
//  CloudXNativeAdView.swift
//
//
//  Created by bkorda on 01.04.2024.
//

import UIKit

/// CloudX native ad templates.
public enum CloudXNativeTemplate: String, Decodable {
    /// Small native ad template also known as logo.
    /// Contains app logo, title, description and CTA button.
    case small = "small"
    
    /// Medium native ad template.
    /// Contains app logo, main image or medi view, title, description and CTA button.
    case medium = "medium"
    
    case smallWithCloseButton = "smallWithCloseButton"
    
    case mediumWithCloseButton = "mediumWithCloseButton"
    
    /// Returns size for the native ad view template.
    public var size: CGSize {
        switch self {
        case .medium:
            return CGSize(width: 320, height: 250)
        case .small:
            return CGSize(width: 320, height: 90)
        case .smallWithCloseButton:
            return CGSize(width: 320, height: 90)
        case .mediumWithCloseButton:
            return CGSize(width: 320, height: 250)
        }
    }
    
    /// Returns UIView of template type.
    public var view: CloudXBaseNativeView {
        switch self {
        case .small:
            return CloudXSmallNativeView(size: self.size)
        case .medium:
            return CloudXMediumNativeView(size: self.size)
        case .smallWithCloseButton:
            return CloudXSmallNativeView(size: self.size, hasCloseButton: true)
        case .mediumWithCloseButton:
            return CloudXMediumNativeView(size: self.size, hasCloseButton: true)
        }
    }
    
    var nativeAdRequirements: NativeAdRequirements {
        switch self {
        case .small:
            return .smallNativeRequest
        case .medium:
            return .mediumNativeRequest
        case .smallWithCloseButton:
            return .smallNativeRequest
        case .mediumWithCloseButton:
            return .mediumNativeRequest
        }
    }
}


/// The native ad view. Add this object to you view ierarchy to display native ads.
public class CloudXNativeAdView: UIView, CloudXAd {
    
    /// Delegate for the native ad view to notify about ad events.
    @objc public weak var delegate: CloudXNativeDelegate?
    
    /// Flag to indicate if the native ad is ready to be shown.
    @objc public var isReady: Bool = false
    
    ///A boolean indicating whether to suspend preloading the ad when it's not visible.
    @objc public var suspendPreloadWhenInvisible: Bool = true {
        didSet {
            self.native.suspendPreloadWhenInvisible = suspendPreloadWhenInvisible
        }
    }
    
    var native: CloudXNative
    
    init(native: CloudXNative, type: CloudXNativeTemplate, delegate: CloudXNativeDelegate?) {
        
        self.delegate = delegate
        self.native = native
        
        super.init(frame: CGRect(origin: .zero, size: type.size))
        
        self.isUserInteractionEnabled = true
        self.native.delegate = self
        self.backgroundColor = .clear
        
        //        self.banner.load()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview != nil {
            native.load()
        }
    }
    
    /// Starts loading the native ad
    @objc public func load() {
        native.load()
    }
    
    /// Destroys the native ad and release all resources
    @objc public func destroy() {
        self.removeFromSuperview()
        native.destroy()
    }
    
}

// TODO: make it private
extension CloudXNativeAdView: AdapterNativeDelegate {
    public func close(native: any AdapterNative) {
        DispatchQueue.main.async {
            self.delegate?.closedByUserAction(on: self)
        }
    }
    
    public func didLoad(native: AdapterNative) {
        guard let nativeView = native.nativeView else {
            DispatchQueue.main.async {
                self.delegate?.failToLoad(ad: self, with: CloudXError.nativeViewError)
            }
            return
        }
        
        nativeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        nativeView.isUserInteractionEnabled = true
        self.addSubview(nativeView)
    }
    
    public func failToLoad(native: AdapterNative?, error: Error?) {
        DispatchQueue.main.async {
            //            let error: CloudXError = error as? CloudXError ?? CloudXError.generalAdError
            self.delegate?.failToLoad(ad: self, with: error ?? CloudXError.generalAdError)
        }
    }
    
    public func didShow(native: AdapterNative) {
        DispatchQueue.main.async {
            self.delegate?.didShow(ad: self)
        }
    }
    
    public func impression(native: AdapterNative) {
        DispatchQueue.main.async {
            self.delegate?.impression(on: self)
        }
    }
    
    public func click(native: AdapterNative) {
        DispatchQueue.main.async {
            self.delegate?.didClick(on: self)
        }
    }
    
}
