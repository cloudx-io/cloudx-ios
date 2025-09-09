//
//  CloudXMintegralBanner.swift
//
//
//  Created by bkorda on 18.07.2024.
//

import CloudXCore
import UIKit
import MTGSDKBanner
import MTGSDKBidding

class CloudXMintegralBanner: NSObject, AdapterBanner {
    weak var delegate: CloudXCore.AdapterBannerDelegate?
    
    var timeout: Bool = false
    
    var bannerView: UIView? {
        banner
    }
    
    var sdkVersion: String = CloudXMintegralInitializer.sdkVersion
    
    private let viewController: UIViewController
    private let type: CloudXBannerType
    private let mtgPlacementID: String
    private let mtgUnitID: String
    private var bidToken: String
    
    private var banner: MTGBannerAdView?
    
    @MainActor
    init(mtgPlacementID: String, mtgUnitID: String, bidToken: String, type: CloudXBannerType, viewController: UIViewController, delegate: AdapterBannerDelegate?) {
        self.delegate = delegate
        self.type = type
        self.viewController = viewController
        self.mtgPlacementID = mtgPlacementID
        self.mtgUnitID = mtgUnitID
        self.bidToken = bidToken
        
        super.init()
        
        banner = MTGBannerAdView(bannerAdViewWithAdSize: type.size, placementId: mtgPlacementID, unitId: mtgUnitID, rootViewController: viewController)
        banner?.autoRefreshTime = 0
        banner?.delegate = self
        banner?.frame = CGRect(x: 0, y: 0, width: type.size.width, height: type.size.height)
    }
    
    func load() {
        self.banner?.loadBannerAd(withBidToken: self.bidToken)
    }
    
    func destroy() {
        banner?.destroy()
    }

}

// MARK: - WKNavigationDelegate

extension CloudXMintegralBanner: MTGBannerAdViewDelegate {
    func adViewLoadSuccess(_ adView: MTGBannerAdView!) {
        delegate?.didLoad(banner: self)
        delegate?.didShow(banner: self)
    }
    
    func adViewLoadFailedWithError(_ error: (any Error)!, adView: MTGBannerAdView!) {
        delegate?.failToLoad(banner: self, error: error)
    }
    
    func adViewWillLogImpression(_ adView: MTGBannerAdView!) {
        delegate?.impression(banner: self)
    }
    
    func adViewDidClicked(_ adView: MTGBannerAdView!) {
        delegate?.click(banner: self)
    }
    
    func adViewWillLeaveApplication(_ adView: MTGBannerAdView!) {}
    
    func adViewWillOpenFullScreen(_ adView: MTGBannerAdView!) {}
    
    func adViewCloseFullScreen(_ adView: MTGBannerAdView!) {}
    
    func adViewClosed(_ adView: MTGBannerAdView!) {}
}

