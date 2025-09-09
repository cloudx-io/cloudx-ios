//
//  CloudXMintegralNative.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import MTGSDKBidding
import MTGSDKNativeAdvanced
import CloudXCore

class CloudXMintegralNative: NSObject, AdapterNative {
    weak var delegate: CloudXCore.AdapterNativeDelegate?
    
    var timeout: Bool = false
    
    lazy var nativeView: UIView? = {
        type.view as? UIView
    }()
    
    var sdkVersion: String = CloudXMintegralInitializer.sdkVersion
    
    private let viewController: UIViewController
    private let type: CloudXNativeTemplate
    private let mtgPlacementID: String
    private let mtgAdUnitID: String
    private var bidToken: String
    
    private var nativeAdManager: MTGBidNativeAdManager?
    
    @MainActor
    init(mtgPlacementID: String, mtgAdUnitID: String, bidToken: String, type: CloudXNativeTemplate, viewController: UIViewController, delegate: AdapterNativeDelegate?) {
        self.delegate = delegate
        self.type = type
        self.viewController = viewController
        self.mtgPlacementID = mtgPlacementID
        self.mtgAdUnitID = mtgAdUnitID
        self.bidToken = bidToken
        
        super.init()
        
        nativeAdManager = MTGBidNativeAdManager(placementId: mtgPlacementID, unitID: mtgAdUnitID, presenting: viewController)
        nativeAdManager?.delegate = self
    }
    
    func load() {
        self.nativeAdManager?.load(withBidToken: self.bidToken)
    }
    
    func destroy() {
        var view = self.nativeView as! CloudXBaseNativeView
        self.nativeAdManager?.unregisterView(view as! UIView, clickableViews: [view.ctaView])
        nativeAdManager = nil
    }
    
}

// MARK: - WKNavigationDelegate


extension CloudXMintegralNative: MTGBidNativeAdManagerDelegate {
    func nativeAdsLoaded(_ nativeAds: [Any]?, bidNativeManager: MTGBidNativeAdManager) {

        Task(priority: .background) {
            if let nativeAds, nativeAds.count > 0,
               let campaign = nativeAds[0] as? MTGCampaign {
                let mainImage =  await campaign.loadImageUrlAsync()
                let appIcon = await campaign.loadIconUrlAsync()
                
                await MainActor.run {
                    var view = self.nativeView as! CloudXBaseNativeView
                    view.mainImage = mainImage
                    view.appIcon = appIcon
                    
                    let mediaView = MTGMediaView()
                    mediaView.setMediaSourceWith(campaign, unitId: self.mtgAdUnitID)
                    mediaView.delegate = self
                    
                    view.customMediaView = mediaView
                    
                    view.descriptionText = campaign.appDesc
                    view.title = campaign.appName
                    view.callToActionText = campaign.adCall
                    
                    self.nativeAdManager?.registerView(forInteraction: view as! UIView, withClickableViews: [view.ctaView], with: campaign)
                    
                    delegate?.didLoad(native: self)
                }
            } else {
                delegate?.failToLoad(native: self, error: CloudXMintegralError.noAds)
            }
        }
    }
    
    func nativeAdDidClick(_ nativeAd: MTGCampaign, bidNativeManager: MTGBidNativeAdManager) {
        delegate?.click(native: self)
    }
    
    func nativeAdImpression(with type: MTGAdSourceType, bidNativeManager: MTGBidNativeAdManager) {
        delegate?.impression(native: self)
    }
    
    func nativeAdsFailedToLoadWithError(_ error: any Error, bidNativeManager: MTGBidNativeAdManager) {
        delegate?.failToLoad(native: self, error: error)
    }
}

extension CloudXMintegralNative: MTGMediaViewDelegate {
    func nativeAdImpression(with type: MTGAdSourceType, mediaView: MTGMediaView) {
        delegate?.impression(native: self)
    }
    
    func nativeAdDidClick(_ nativeAd: MTGCampaign, mediaView: MTGMediaView) {
        delegate?.click(native: self)
    }
}
