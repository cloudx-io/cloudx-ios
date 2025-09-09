//
//  AdNetworkFactories.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import Foundation

protocol AdapterFactoryResolverProtocol {
    func resolveAdNetworkFactories() -> AdNetworkFactories
}

struct AdNetworkFactories {
    var bidTokenSources: [SDKConfig.KnownAdapterName: BidTokenSource]
    var initialisers: [SDKConfig.KnownAdapterName: AdNetworkInitializer]
    var interstitials: [SDKConfig.KnownAdapterName: AdapterInterstitialFactory]
    var rewardedInterstitials:  [SDKConfig.KnownAdapterName : AdapterRewardedFactory]
    var banners: [SDKConfig.KnownAdapterName : AdapterBannerFactory]
    var native: [SDKConfig.KnownAdapterName : AdapterNativeFactory]
    
    /// ✅ Helper function to check if all fields are empty
    var isEmpty: Bool {
        return bidTokenSources.isEmpty &&
               initialisers.isEmpty &&
               interstitials.isEmpty &&
               rewardedInterstitials.isEmpty &&
               banners.isEmpty &&
               native.isEmpty
    }
}
