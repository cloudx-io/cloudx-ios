//
//  PublisherAdFactory.swift
//  
//
//  Created by bkorda on 04.03.2024.
//

import UIKit
import Combine

struct AdFactoryKey: Hashable {
    let viewController: UIViewController
    let placementID: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.viewController == rhs.viewController && lhs.placementID == rhs.placementID
    }
}

class PublisherAdFactory {
    
    private var cache: [AdFactoryKey : CloudXAd] = [:]
    private var cancelableBag: [AnyCancellable] = []
    
    var cancelable: AnyCancellable?
    
    func createNewInterstitial(
        placement: SDKConfig.Response.Placement?,
        delegate: CloudXInterstitialDelegate?,
        userID: String,
        publisherID: String,
        interstitialFactories: AdNetworkFactories?,
        bidTokenSources: [String : BidTokenSource]?,
        cacheSize: Int?,
        reportingService: AdEventReporting) -> CloudXInterstitial? {
        
        guard let placement = placement,
              let interstitialFactories = interstitialFactories,
              let cacheSize = cacheSize else {
            return nil
        }
        
        
        return PublisherFullscreenAd(
            interstitialDelegate: delegate,
            placement: placement,
            publisherID: publisherID,
            userID: userID,
            cacheSize: cacheSize,
            adFactories: interstitialFactories,
            waterfallMaxBackOffTime: 10,
            bidTokenSources: [:],
            bidRequestTimeout: 3,
            reportingService: reportingService,
            adType: .interstitial)
    }
    
    func createNewRewarded(
        placement: SDKConfig.Response.Placement?,
        delegate: CloudXRewardedDelegate?,
        userID: String,
        publisherID: String,
        rewardedFactories: AdNetworkFactories?,
        bidTokenSources: [String : BidTokenSource]?,
        cacheSize: Int?,
        reportingService: AdEventReporting) -> CloudXRewardedInterstitial? {
        
        guard let placement = placement,
              let rewardedFactories = rewardedFactories,
              let cacheSize = cacheSize else {
            return nil
        }
        
        
        return PublisherFullscreenAd(
            rewardedDelegate: delegate,
            placement: placement,
            publisherID: publisherID,
            userID: userID,
            cacheSize: cacheSize,
            adFactories: rewardedFactories,
            waterfallMaxBackOffTime: 5,
            bidTokenSources: [:],
            bidRequestTimeout: 3,
            reportingService: reportingService,
            adType: .rewarded)
    }
    
    func createBanner(
        viewController: UIViewController,
        placement: SDKConfig.Response.Placement?,
        impModel: ConfigImpressionModel,
        apiKey: String,
        userID: String,
        publisherID: String,
        type: CloudXBannerType,
        bannerFactories: @escaping () -> [SDKConfig.KnownAdapterName : AdapterBannerFactory]?,
        bidTokenSource: @escaping () -> [SDKConfig.KnownAdapterName : BidTokenSource]?,
        reportingService: @escaping () -> AdEventReporting
    ) -> CloudXBanner {
        
        let banner = self.createNewBanner(viewController: viewController, placement: placement, impModel: impModel, apiKey: apiKey, userID: userID, publisherID: publisherID, type: type, bannerFactories: bannerFactories(), bidTokenSource: bidTokenSource(), reportingService: reportingService())
        
        return banner
    }
    
    private func createNewBanner(viewController: UIViewController,
                                 placement: SDKConfig.Response.Placement?,
                                 impModel: ConfigImpressionModel,
                                 apiKey: String,
                                 userID: String,
                                 publisherID: String,
                                 type: CloudXBannerType,
                                 bannerFactories: [SDKConfig.KnownAdapterName : AdapterBannerFactory]?,
                                 bidTokenSource: [SDKConfig.KnownAdapterName : BidTokenSource]?,
                                 reportingService: AdEventReporting) -> CloudXBanner {
        
        guard let placement = placement else {
            let invalidBanner = InvalidBanner(error: CloudXError.invalidPlacement)
            return invalidBanner
        }
        
        guard let bannerFactories = bannerFactories, !bannerFactories.isEmpty else {
            let invalidBanner = InvalidBanner(error: CloudXError.sdkInitializedWithoutAdapters)
            return invalidBanner
        }
        
        guard let bidTokenSource = bidTokenSource else {
            let invalidBanner = InvalidBanner(error: CloudXError.noBidTokenSource)
            return invalidBanner
        }
        
        return PublisherBanner(
            viewController: viewController,
            placement: placement,
            userID: userID,
            publisherID: publisherID,
            suspendPreloadWhenInvisible: false,
            bannerType: type,
            waterfallMaxBackOffTime: 5,
            impModel: impModel,
            adFactories: bannerFactories,
            bidTokenSources: bidTokenSource,
            bidRequestTimeout: 3,
            reportingService: reportingService)
    }
    
    func createNative(
        viewController: UIViewController,
        placement: SDKConfig.Response.Placement?,
        apiKey: String,
        userID: String,
        publisherID: String,
        type: CloudXNativeTemplate,
        nativeFactories: @escaping () -> [SDKConfig.KnownAdapterName : AdapterNativeFactory]?,
        reportingService: @escaping () -> AdEventReporting
    ) -> CloudXNative? {
        
        return self.createNewNativeAd(viewController: viewController, placement: placement, apiKey: apiKey, userID: userID, publisherID: publisherID, type: type, nativeFactories: nativeFactories(), reportingService: reportingService())
    }
    
    private func createNewNativeAd(viewController: UIViewController,
                                 placement: SDKConfig.Response.Placement?,
                                 apiKey: String,
                                 userID: String,
                                 publisherID: String,
                                 type: CloudXNativeTemplate,
                                 nativeFactories: [SDKConfig.KnownAdapterName : AdapterNativeFactory]?,
                                 reportingService: AdEventReporting) -> CloudXNative? {
        
        guard let placement = placement,
              let nativeFactories = nativeFactories else {
            return nil
        }
        
        return PublisherNative(
            viewController: viewController,
            placement: placement,
            userID: userID,
            publisherID: publisherID,
            suspendPreloadWhenInvisible: false,
            nativeType: type,
            waterfallMaxBackOffTime: 5,
            adFactories: nativeFactories,
            bidTokenSources: [:],
            bidRequestTimeout: 3,
            reportingService: reportingService)
    }
}
