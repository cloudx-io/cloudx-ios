//
//  CloudXMintegralRewarded.swift
//
//
//  Created by bkorda on 19.07.2024.
//
import MTGSDKReward
import MTGSDKBidding
import CloudXCore

final class CloudXMintegralRewarded: NSObject, AdapterRewarded {
    var network: String { "Mintegral" }
    
    weak var delegate: AdapterRewardedDelegate?
    
    var isReady: Bool {
        return rewarded != nil
    }
    
    var sdkVersion: String {
        return CloudXMintegralInitializer.sdkVersion
    }
    
    let mtgPlacementID: String
    let bidID: String
    let mtgAdUnitID: String
    private var bidToken: String
    private var rewarded: MTGBidRewardAdManager?
    
    // MARK: - Init
    
    init(mtgPlacementID: String, mtgAdUnitID: String, bidToken: String, bidID: String, delegate: AdapterRewardedDelegate?) {
        self.delegate = delegate
        self.mtgPlacementID = mtgPlacementID
        self.bidID = bidID
        self.mtgAdUnitID = mtgAdUnitID
        self.bidToken = bidToken
        
        super.init()
        
        rewarded = MTGBidRewardAdManager.sharedInstance()
    }
    
    func load() {
        self.rewarded?.loadVideo(withBidToken: self.bidToken, placementId: self.mtgPlacementID, unitId: self.mtgAdUnitID, delegate: self)
    }
    
    func show(from viewController: UIViewController) {
        rewarded?.showVideo(withPlacementId: mtgPlacementID, unitId: mtgAdUnitID, userId: nil, delegate: self, viewController: viewController)
    }
    
    func destroy() {
        
    }
}

// MARK: - FullscreenStaticContainerViewControllerDelegate

extension CloudXMintegralRewarded: MTGRewardAdLoadDelegate, MTGRewardAdShowDelegate {
    func onVideoAdLoadSuccess(_ placementId: String?, unitId: String?) {
        delegate?.didLoad(rewarded: self)
    }
    
    func onVideoAdClicked(_ placementId: String?, unitId: String?) {
        delegate?.click(rewarded: self)
    }
    
    func onVideoAdDismissed(_ placementId: String?, unitId: String?, withConverted converted: Bool, withRewardInfo rewardInfo: MTGRewardAdInfo?) {
        delegate?.didClose(rewarded: self)
    }
    
    func onVideoAdShowFailed(_ placementId: String?, unitId: String?, withError error: any Error) {
        delegate?.didFailToShow(rewarded: self, error: error)
    }
    
    func onVideoAdLoadFailed(_ placementId: String?, unitId: String?, error: any Error) {
        delegate?.didFailToLoad(rewarded: self, error: error)
    }
    
    func onVideoPlayCompleted(_ placementId: String?, unitId: String?) {
        delegate?.userReward(rewarded: self)
    }
    
    func onVideoAdShowSuccess(_ placementId: String?, unitId: String?, bidToken: String?) {
        delegate?.didShow(rewarded: self)
        delegate?.impression(rewarded: self)
    }
    
}


