//
//  CloudXBannerAdView.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import UIKit

/// `CloudXBannerType` is a public enumeration that represents different types of banner ads that can be served.
/// This enumeration can be used to specify the type and size of a banner ad when requesting ads from the CloudX SDK.
@objc public enum CloudXBannerType: Int {
    /// This case represents a banner ad with a width of 320 and a height of 50.
    /// If the device type is a tablet, the size is adjusted to 728x90.
    case w320h50 = 0
    /// This case represents a medium rectangle ad (also known as "medium rectangle") with a size of 300x250.
    case mrec = 1
    
    /// This computed property returns the size of the banner ad as a `CGSize` based on the enumeration case.
    /// The size is determined by the device type for the `w320h50` case.
    public var size: CGSize {
        switch self {
        case .mrec:
            return CGSize(width: 300, height: 250)
        case .w320h50:
            if SystemInformation.shared.deviceType == .tablet {
                //728 x 90
                return CGSize(width: 728, height: 90)
            } else {
                return CGSize(width: 320, height: 50)
            }
        }
    }
}

/// `CloudXBannerAdView` is represents a banner ad view in the CloudX SDK.
public class CloudXBannerAdView: UIView, CloudXAd {
    private let logger = Logger(category: "CloudXBannerAdView")
    
    /// A weak reference to the object that implements `CloudXBannerDelegate` protocol. This object will receive events related to the banner ad.
    @objc public weak var delegate: CloudXBannerDelegate?
    
    /// A boolean indicating whether the ad is loaded and ready to be shown.
    @objc public var isReady: Bool = false
    
    /// A boolean indicating whether to suspend preloading the ad when it's not visible.
    @objc public var suspendPreloadWhenInvisible: Bool = true {
        didSet {
            self.banner.suspendPreloadWhenInvisible = suspendPreloadWhenInvisible
        }
    }
    
    // An instance of `CloudXBanner` that represents the banner ad.
    var banner: CloudXBanner
    
    // Initializes a new `CloudXBannerAdView` with the given banner, type, and delegate. The frame of the view is set based on the size of the banner type.
    init(banner: CloudXBanner, type: CloudXBannerType, delegate: CloudXBannerDelegate?) {
        logger.debug("Initializing with type: \(type)")
        self.delegate = delegate
        self.banner = banner
        
        super.init(frame: CGRect(origin: .zero, size: type.size))
        
        self.isUserInteractionEnabled = true
        self.banner.delegate = self
        self.backgroundColor = .clear
        
        logger.debug("Initialized successfully")
        
        //auto load banner
        //        self.banner.load()
    }
    
    //A required initializer for `NSCoding` protocol. It's not implemented in this class and will cause a runtime error if called.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Overrides the method from `UIView`. It loads the banner ad when the view is added to a superview.
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview != nil {
            logger.debug("Added to superview, initiating banner load")
            banner.load()
        } else {
            logger.debug("Removed from superview")
        }
    }
    
    /// Starts banner loading process.
    /// It should be called once after the banner is created.
    /// Banner wil be automatically reloaded after each show based on placement settings.
    @objc public func load() {
        logger.debug("Manual load() called")
        banner.load()
    }
    
    ///Removes the view from its superview and destroys the banner ad.
    @objc public func destroy() {
        self.removeFromSuperview()
        banner.destroy()
    }
    
}

//TODO: make it private
extension CloudXBannerAdView: AdapterBannerDelegate {
    public func closedByUserAction(banner: any AdapterBanner) {
        logger.debug("closedByUserAction callback")
        DispatchQueue.main.async {
            self.delegate?.closedByUserAction(on: self)
        }
    }
    
    ///Adapter callback. Do not call this method directly.
    public func didLoad(banner: AdapterBanner) {
        logger.debug("didLoad callback received")
        guard let bannerView = banner.bannerView else {
            logger.debug("didLoad failed: bannerView is nil")
            DispatchQueue.main.async {
                self.delegate?.failToLoad(ad: self, with: CloudXError.bannerViewError)
            }
            return
        }
        
        logger.debug("Adding banner view to view hierarchy")
        bannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bannerView.isUserInteractionEnabled = true
        self.addSubview(bannerView)
        
        // Set frame to match parent view
        bannerView.frame = self.bounds
        logger.debug("Banner view added with frame: \(bannerView.frame)")
    }
    
    ///Adapter callback. Do not call this method directly.
    public func failToLoad(banner: AdapterBanner?, error: Error?) {
        logger.debug("failToLoad callback with error: \(String(describing: error))")
        DispatchQueue.main.async {
            self.delegate?.failToLoad(ad: self, with: error ?? CloudXError.generalAdError)
        }
    }
    
    ///Adapter callback. Do not call this method directly.
    public func didShow(banner: AdapterBanner) {
        logger.debug("didShow callback")
        DispatchQueue.main.async {
            self.delegate?.didShow(ad: self)
        }
    }
    
    ///Adapter callback. Do not call this method directly.
    public func impression(banner: AdapterBanner) {
        logger.debug("impression callback")
        DispatchQueue.main.async {
            self.delegate?.impression(on: self)
        }
    }
    
    ///Adapter callback. Do not call this method directly.
    public func click(banner: AdapterBanner) {
        logger.debug("click callback")
        DispatchQueue.main.async {
            self.delegate?.didClick(on: self)
        }
    }
    
}
