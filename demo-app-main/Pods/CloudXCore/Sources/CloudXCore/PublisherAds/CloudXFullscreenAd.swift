//
//  PublisherFullscreenAd.swift
//  
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

// MARK: - CloudXInterstitial protocol

///`CloudXAd` is a base protocol for fullscreen ad types in the CloudX SDK.
@objc public protocol CloudXFullscreenAd: CloudXAd {
    ///Shows the interstitial ad from the provided view controller.
    func show(from viewController: UIViewController)
}

///`CloudXInterstitial` is an interface of interstitial ad in the CloudX SDK. It inherits from the `CloudXAd` protocol.
@objc public protocol CloudXInterstitial: CloudXFullscreenAd {
    ///An optional delegate that conforms to the `CloudXInterstitialDelegate` protocol. This delegate will receive events related to the interstitial ad.
    @objc var interstitialDelegate: CloudXInterstitialDelegate? { get set }
}

///`CloudXRewardedInterstitial`is an interface of a rewarded interstitial ad in the CloudX SDK. It inherits from the `CloudXAd` protocol.
public protocol CloudXRewardedInterstitial: CloudXFullscreenAd {
    ///An optional delegate that conforms to the `CloudXRewardedDelegate` protocol. This delegate will receive events related to the rewarded interstitial ad.
    var rewardedDelegate: CloudXRewardedDelegate? { get set }
}

final class PublisherFullscreenAd: NSObject {
    // MARK: - Properties
    
    weak var interstitialDelegate: CloudXInterstitialDelegate?
    weak var rewardedDelegate: CloudXRewardedDelegate?
    
    var isReady: Bool {
        cachedAdService.hasAds
    }
    
    private let adFactories: AdNetworkFactories?
    private var cachedAdService: CacheAdService!
    private let userID: String?
    private let reportingService: AdEventReporting
    private let placementID: String
//    private let adRequestResponseEventHandler: AdRequestResponseEventHandler
    
    private let rewardedCallbackUrl: String?
    
    //sometimes we don't receive close ad event. So need to fire it myself after N seconds
    private var closeTimer: Timer?
    private let forceCloseEventDelay: TimeInterval = 30
    private var closeEventReceived: Bool = false
    private var firstClick: Bool = false
    private var adType: SDKConfig.Response.Placement.AdType
    private var currentAd: CacheableAd?
    private let logger = Logger(category: "FullscreenAd")
    private var impressionTime: Date?
    @Service(.singleton) private var appSessionService: AppSessionService
    
    init(interstitialDelegate: CloudXInterstitialDelegate? = nil,
         rewardedDelegate: CloudXRewardedDelegate? = nil,
         placement: SDKConfig.Response.Placement,
         publisherID: String,
         userID: String?,
         rewardedCallbackUrl: String? = nil,
         cacheSize: Int,
         adFactories: AdNetworkFactories?,
         waterfallMaxBackOffTime: TimeInterval?,
         bidTokenSources: [SDKConfig.KnownAdapterName : BidTokenSource],
         bidRequestTimeout: TimeInterval,
         reportingService: AdEventReporting,
         adType: SDKConfig.Response.Placement.AdType) {
        
        self.interstitialDelegate = interstitialDelegate
        self.rewardedDelegate = rewardedDelegate
        self.adFactories = adFactories
        self.rewardedCallbackUrl = rewardedCallbackUrl
        self.placementID = placement.id
        
        self.reportingService = reportingService
        self.userID = userID
        self.adType = adType
        
        super.init()
        
        var bidSource: BidAdSource?
            
        bidSource = BidAdSource(userID: userID, placementID: placementID, dealID: placement.dealId, hasCloseButton: false, publisherID: publisherID, adType: adType == .interstitial ? .interstitial : .rewarded, bidTokenSources: bidTokenSources, nativeAdRequirements: nil, createBidAd: { [weak self]  adId,bidId,adm,adapterExtras,burl,hasCloseButton,network  in
            adType == .interstitial ? self?.createInterstitialInstance(adId: adId, bidId: bidId, adm: adm, adapterExtras: adapterExtras, burl: burl, network: network) : self?.createRewardedInstance(adId: adId, bidId: bidId, adm: adm, adapterExtras: adapterExtras, burl: burl, network: network)
        })
        
        cachedAdService = CacheAdService(
            placement: placement,
            bidAdSource: bidSource,
            waterfallMaxBackOffTime: waterfallMaxBackOffTime,
            cacheSize: cacheSize, 
            bidLoadTimeout: bidRequestTimeout,
            reportingService: reportingService) { destroyable -> CacheableAd? in
                if adType == .interstitial {
                    guard let interstitial = destroyable as? AdapterInterstitial else {
                        return nil
                    }
                    
                    return CachedInterstitial(interstitial: interstitial, delegate: self)
                } else {
                    guard let rewarded = destroyable as? AdapterRewarded else {
                        self.logger.debug("cachedAdService ")
                        return nil
                    }
                    self.logger.debug("CachedRewarded \(rewarded)")
                    return CachedRewarded(rewarded: rewarded, delegate: self)
                }
            }
    }
    
    // MARK: - Factory For Creating bidder or waterfall
    private func createInterstitialInstance(adId: String, bidId: String, adm: String, adapterExtras: [String: String], burl: String?, network: SDKConfig.KnownAdapterName) -> Destroyable? {
        guard
            let factory = adFactories?.interstitials[network],
            let bidInterstitial = factory.create(adId: adId, bidId: bidId, adm: adm, extras: adapterExtras, delegate: self)
        else {
            return nil
        }
        
        return bidInterstitial
    }
    
    private func createRewardedInstance(adId: String, bidId: String, adm: String, adapterExtras: [String: String], burl: String?,  network: SDKConfig.KnownAdapterName) -> Destroyable? {
        guard
            let factory = adFactories?.rewardedInterstitials[network],
            let bidRewarded = factory.create(adId: adId, bidId: bidId, adm: adm, extras: adapterExtras, delegate: self)
        else {
            return nil
        }
        logger.debug("createRewardedInstance \(adId), \(bidId), \(adm)")
        return bidRewarded
    }
}

// MARK: - CloudXInterstitialRewarded

extension PublisherFullscreenAd: CloudXInterstitial, CloudXRewardedInterstitial {
    
    ///Start loading the interstitial ad.
    ///If ad is already loaded, it will call `didLoad` method of the delegate.
    ///Interstitial ad contains a queue of precached ads.
    func load() {
        if self.cachedAdService.hasAds {
            DispatchQueue.main.async {
                switch self.adType {
                case .interstitial:
                    self.interstitialDelegate?.didLoad(ad: self)
                case .rewarded:
                    self.rewardedDelegate?.didLoad(ad: self)
                default:
                    break
                }
            }
        } else {
            DispatchQueue.main.async {
                switch self.adType {
                case .interstitial:
                    self.interstitialDelegate?.failToLoad(ad: self, with: CloudXError.noAdsLoaded)
                case .rewarded:
                    self.rewardedDelegate?.failToLoad(ad: self, with: CloudXError.noAdsLoaded)
                default:
                    break
                }
            }
        }
    }
    
    
    @MainActor
    /// Show the interstitial ad from the provided view controller.
    /// - Parameter viewController: The view controller from which the interstitial ad will be shown.
    func show(from viewController: UIViewController) {
        self.closeEventReceived = false
        self.closeTimer = Timer.init(timeInterval: self.forceCloseEventDelay, repeats: false, block: { [weak self] timer in
            guard let self = self else { return }
            if !self.closeEventReceived {
                self.interstitialDelegate?.didHide(ad: self)
                self.rewardedDelegate?.didHide(ad: self)
            }
            self.closeTimer?.invalidate()
        })
        
        logger.debug("Showing interstitial ad")
        currentAd = self.cachedAdService.popAd()
        currentAd?.show(from: viewController)
    }
    
    /// Destroy the interstitial ad.
    @objc public func destroy() {
        logger.debug(#function)
        cachedAdService.destroy()
    }
    
    private func applyMetrics() {
        if let metrics = (currentAd as? MetricDecorator) {
            appSessionService.addSpend(placementID: placementID, spend: metrics.price)
        }
    }
}

// MARK: - InterstitialDelegate

extension PublisherFullscreenAd: AdapterInterstitialDelegate {
    func didLoad(interstitial: AdapterInterstitial) {
//        DispatchQueue.main.async {
//            self.interstitialDelegate?.didLoad(ad: self)
//        }
    }
    
    func didShow(interstitial: AdapterInterstitial) {
        DispatchQueue.main.async {
            self.interstitialDelegate?.didShow(ad: self)
        }
    }
    
    //TODO: burl
    func impression(interstitial: AdapterInterstitial) {
        self.impressionTime = Date()
        reportingService.impression(bidID: interstitial.bidID)
        applyMetrics()
        appSessionService.addImpression(placementID: placementID)
        self.interstitialDelegate?.impression(on: self)
    }
    
    func didClose(interstitial: AdapterInterstitial) {
        if let impressionTime {
            let latency = Date().timeIntervalSince(impressionTime).milliseconds
            appSessionService.addClose(placementID: placementID, latency: latency)
        } else {
            logger.debug("no impression event")
        }
        
        self.closeEventReceived = true
        self.closeTimer?.invalidate()
        interstitial.destroy()
        DispatchQueue.main.async {
            self.interstitialDelegate?.didHide(ad: self)
        }
    }
    
    func didFailToLoad(interstitial: AdapterInterstitial, error: Error) {
        logger.debug("Failed to load interstitial ad " + error.localizedDescription)
        DispatchQueue.main.async {
            self.interstitialDelegate?.failToLoad(ad: self, with: error)
        }
    }
    
    func didFailToShow(interstitial: AdapterInterstitial, error: Error) {
        DispatchQueue.main.async {
            self.interstitialDelegate?.failToShow(ad: self, with: error)
        }
    }
    
    func click(interstitial: AdapterInterstitial) {
        logger.debug("Clicked on interstitial ad")
        appSessionService.addClick(placementID: placementID)
        DispatchQueue.main.async {
            self.interstitialDelegate?.didClick(on: self)
        }
    }
    
    //TODO:
    func expired(interstitial: AdapterInterstitial) {
        self.cachedAdService.adError(ad: interstitial)
    }
}

// MARK: - RewardedInterstitialDelegate

extension PublisherFullscreenAd: AdapterRewardedDelegate {
    
    func didLoad(rewarded: AdapterRewarded) {
//        DispatchQueue.main.async {
//            self.rewardedDelegate?.didLoad(ad: self)
//        }
    }
    
    func didShow(rewarded: AdapterRewarded) {
        DispatchQueue.main.async {
            self.rewardedDelegate?.didShow(ad: self)
        }
    }
    
    //TODO: burl
    func impression(rewarded: AdapterRewarded) {
        self.impressionTime = Date()
        reportingService.impression(bidID: rewarded.bidID)
        applyMetrics()
        appSessionService.addImpression(placementID: placementID)
        self.rewardedDelegate?.impression(on: self)
    }
    
    func didClose(rewarded: AdapterRewarded) {
        if let impressionTime {
            let latency = Date().timeIntervalSince(impressionTime).milliseconds
            appSessionService.addClose(placementID: placementID, latency: latency)
        } else {
            logger.debug("no impression event")
        }
        
        self.closeEventReceived = true
        self.closeTimer?.invalidate()
        rewarded.destroy()
        DispatchQueue.main.async {
            self.rewardedDelegate?.didHide(ad: self)
        }
    }
    
    func didFailToLoad(rewarded: AdapterRewarded, error: Error) {
        logger.error("Failed to load rewarded ad " + error.localizedDescription)
        DispatchQueue.main.async {
            self.rewardedDelegate?.failToLoad(ad: self, with: CloudXError.noAdsLoaded)
        }
    }
    
    //TODO: rewarded callback
    func click(rewarded: AdapterRewarded) {
        logger.debug("Clicked on interstitial ad")
        appSessionService.addClick(placementID: placementID)
        DispatchQueue.main.async {
            self.rewardedDelegate?.didClick(on: self)
        }
    }
    
    func rewardedVideoDidStart(rewarded: AdapterRewarded) {
        DispatchQueue.main.async {
            self.rewardedDelegate?.rewardedVideoStarted(ad: self)
        }
    }
    
    func userReward(rewarded: AdapterRewarded) {
        //        if let rewardedCallbackUrl = rewardedCallbackUrl,
        //           let dcrInfo = rewarded as? DCRAdParams {
        //            RewardedCallbackService.service.sendRewardedCallback(url: rewardedCallbackUrl, userId: self.userId ?? "", country: self.country, adUnitId: dcrInfo.adUnitID, adUnitName: dcrInfo.adUnitName, networkName: dcrInfo.network, placementName: self.placementName, ip: self.ip, impressionId: dcrInfo.impressionId.uuidString, accessKey: CloudX.shared.acsKey)
        //        }
        logger.debug("User rewarded")
        DispatchQueue.main.async {
            self.rewardedDelegate?.rewardedVideoCompleted(ad: self)
            self.rewardedDelegate?.userRewarded(ad: self)
        }
    }
    
    func didFailToShow(rewarded: AdapterRewarded, error: Error) {
        DispatchQueue.main.async {
            self.rewardedDelegate?.failToShow(ad: self, with: error)
        }
    }
    
    //TODO: 
    func expired(rewarded: AdapterRewarded) {
        
    }
}
