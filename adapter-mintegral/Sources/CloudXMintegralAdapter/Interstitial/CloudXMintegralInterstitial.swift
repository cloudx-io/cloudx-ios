//
//  CloudXMintegralInterstitial.swift
//
//
//  Created by bkorda on 18.07.2024.
//
import CloudXCore
import MTGSDKNewInterstitial
import MTGSDKBidding

enum CloudXMintegralError: Error {
    case adInvalid
    case noAds
}

final class CloudXMintegralInterstitial: NSObject, AdapterInterstitial {
    var network: String { "Mintegral" }
    
    weak var delegate: AdapterInterstitialDelegate?
    
    var isReady: Bool {
        interstitial?.isAdReady() == true
    }
    
    var sdkVersion: String = CloudXMintegralInitializer.sdkVersion
    
    let mtgPlacementID: String
    let bidID: String
    let mtgAdUnitID: String
    private var interstitial: MTGNewInterstitialBidAdManager?
    private var bidToken: String
    
    // MARK: - Init
    
    deinit {
        print("AAA deinit \(self)")
    }
    
    init(mtgPlacementID: String, mtgAdUnitID: String, bidToken: String, bidID: String, delegate: AdapterInterstitialDelegate?) {
        self.delegate = delegate
        self.mtgPlacementID = mtgPlacementID
        self.bidID = bidID
        self.mtgAdUnitID = mtgAdUnitID
        self.bidToken = bidToken
        
        super.init()
        
        interstitial = MTGNewInterstitialBidAdManager(placementId: mtgPlacementID, unitId: mtgAdUnitID, delegate: self)
        
    }
    
    func load() {
        self.interstitial?.loadAd(withBidToken: self.bidToken)
    }
    
    func show(from viewController: UIViewController) {
        if interstitial?.isAdReady() == true {
            interstitial?.show(from: viewController)
            delegate?.didShow(interstitial: self)
        } else {
            delegate?.didFailToShow(interstitial: self, error: CloudXMintegralError.adInvalid)
        }
    }
    
    func destroy() {
        
    }
}

// MARK: - FullscreenStaticContainerViewControllerDelegate

extension CloudXMintegralInterstitial: MTGNewInterstitialBidAdDelegate {
    
    func newInterstitialBidAdLoadSuccess(_ adManager: MTGNewInterstitialBidAdManager) {
        delegate?.didLoad(interstitial: self)
    }
    
    func newInterstitialBidAdResourceLoadSuccess(_ adManager: MTGNewInterstitialAdManager) {
        delegate?.didLoad(interstitial: self)
    }
    
    func newInterstitialBidAdLoadFail(_ error: any Error, adManager: MTGNewInterstitialBidAdManager) {
        delegate?.didFailToLoad(interstitial: self, error: error)
    }
    
    func newInterstitialBidAdLoadFail(_ error: any Error, adManager: MTGNewInterstitialAdManager) {
        delegate?.didFailToLoad(interstitial: self, error: error)
    }
    
    func newInterstitialBidAdShowSuccess(_ adManager: MTGNewInterstitialBidAdManager) {
        delegate?.didShow(interstitial: self)
        delegate?.impression(interstitial: self)
    }
    
    func newInterstitialBidAdClicked(_ adManager: MTGNewInterstitialBidAdManager) {
        delegate?.click(interstitial: self)
    }
    
    func newInterstitialBidAdDismissed(withConverted converted: Bool, adManager: MTGNewInterstitialBidAdManager) {
        delegate?.didClose(interstitial: self)
    }
    
    func newInterstitialBidAdShowFail(_ error: any Error, adManager: MTGNewInterstitialBidAdManager) {
        delegate?.didFailToShow(interstitial: self, error: error)
    }
    
}


