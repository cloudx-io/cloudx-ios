//
//  AdapterFactoryResolver.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import Foundation

enum ClassNameConstants {
    static let prefix = "CloudX"
    static let factory = "Factory"
    static let adapter = "Adapter"
    static let initializer = "Initializer"
    static let interstitial = "Interstitial"
    static let rewarded = "Rewarded"
    static let banner = "Banner"
    static let native = "Native"
    static let tokenSource = "BidTokenSource"
    static let parameter = "Parameter"
    static let handler = "Handler"
}

struct AdapterFactoryResolver: AdapterFactoryResolverProtocol {
    
    func register(network: String,
                  initializer: AdNetworkInitializer,
                  bannerFactory: AdapterBannerFactory,
                  interstitialFactory: AdapterInterstitialFactory,
                  rewardedFactory: AdapterRewardedFactory,
                  nativeFactory: AdapterNativeFactory) {
        
    }
    
    func resolveAdNetworkFactories() -> AdNetworkFactories {
        var initializers = [SDKConfig.KnownAdapterName: AdNetworkInitializer]()
        var interstitials = [SDKConfig.KnownAdapterName :  AdapterInterstitialFactory]()
        var rewardedInterstitials = [SDKConfig.KnownAdapterName : AdapterRewardedFactory]()
        var banners = [SDKConfig.KnownAdapterName: AdapterBannerFactory]()
        var natives = [SDKConfig.KnownAdapterName: AdapterNativeFactory]()
        var tokenSources = [SDKConfig.KnownAdapterName : BidTokenSource]()
        
        print("[CloudX][FactoryResolver] Starting factory resolution for adapters: \(SDKConfig.KnownAdapterName.allCases)")
        for adapterName in SDKConfig.KnownAdapterName.allCases {
            let namespace = "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.adapter)"
            
            let initializerClass = loadClassInstance(namespace: namespace, className: "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.initializer)") as? AdNetworkInitializer
            if initializerClass == nil { print("[CloudX][FactoryResolver] Initializer NOT found for adapter: \(adapterName)") } else { print("[CloudX][FactoryResolver] Initializer found for adapter: \(adapterName)") }
            initializers[adapterName] = initializerClass
            
            let interstitialClass = loadClassInstance(namespace: namespace, className: "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.interstitial)\(ClassNameConstants.factory)") as? AdapterInterstitialFactory
            if interstitialClass == nil { print("[CloudX][FactoryResolver] InterstitialFactory NOT found for adapter: \(adapterName)") } else { print("[CloudX][FactoryResolver] InterstitialFactory found for adapter: \(adapterName)") }
            interstitials[adapterName] = interstitialClass
            
            let rewardedClass = loadClassInstance(namespace: namespace, className: "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.rewarded)\(ClassNameConstants.factory)") as? AdapterRewardedFactory
            if rewardedClass == nil { print("[CloudX][FactoryResolver] RewardedFactory NOT found for adapter: \(adapterName)") } else { print("[CloudX][FactoryResolver] RewardedFactory found for adapter: \(adapterName)") }
            rewardedInterstitials[adapterName] = rewardedClass
            
            let bannerClass = loadClassInstance(namespace: namespace, className: "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.banner)\(ClassNameConstants.factory)") as? AdapterBannerFactory
            if bannerClass == nil { print("[CloudX][FactoryResolver] BannerFactory NOT found for adapter: \(adapterName)") } else { print("[CloudX][FactoryResolver] BannerFactory found for adapter: \(adapterName)") }
            banners[adapterName] = bannerClass
            
            let nativeClass = loadClassInstance(namespace: namespace, className: "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.native)\(ClassNameConstants.factory)") as? AdapterNativeFactory
            if nativeClass == nil { print("[CloudX][FactoryResolver] NativeFactory NOT found for adapter: \(adapterName)") } else { print("[CloudX][FactoryResolver] NativeFactory found for adapter: \(adapterName)") }
            natives[adapterName] = nativeClass
            
            let tokenSourceClass = loadClassInstance(namespace: namespace, className: "\(ClassNameConstants.prefix)\(adapterName.className)\(ClassNameConstants.tokenSource)") as? BidTokenSource
            if tokenSourceClass == nil { print("[CloudX][FactoryResolver] TokenSource NOT found for adapter: \(adapterName)") } else { print("[CloudX][FactoryResolver] TokenSource found for adapter: \(adapterName)") }
            tokenSources[adapterName] = tokenSourceClass
        }
        print("[CloudX][FactoryResolver] Factory resolution complete. Banner factories: \(banners)")
        return AdNetworkFactories(
            bidTokenSources: tokenSources, initialisers: initializers, interstitials: interstitials, rewardedInterstitials: rewardedInterstitials, banners: banners, native: natives)
    }
    
    private func loadClassInstance(namespace: String, className: String) -> Any? {
        guard let classInstance = ClassLoader.loadClass(namespace: namespace, className: className)?.createInstance() else {
            return nil
        }
        return classInstance
    }
}
