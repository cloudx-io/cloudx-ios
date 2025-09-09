//
//  CloudXDSPRewarded.swift
//
//
//  Created by bkorda on 06.03.2024.
//
import WebKit
import SafariServices
import CloudXCore

final class CloudXDSPRewarded: NSObject, AdapterRewarded {
    var network: String { "DSP" }
    
    weak var delegate: AdapterRewardedDelegate?
    
    var isReady: Bool {
        return containerViewController != nil
    }
    
    var sdkVersion: String {
        return CloudX.shared.sdkVersion
    }
    let bidID: String
    
    private let adm: String
    private var containerViewController: FullscreenStaticContainerViewController?
    
    // MARK: - Init
    
    init(adm: String, bidID: String, delegate: AdapterRewardedDelegate?) {
        self.delegate = delegate
        self.adm = adm
        self.bidID = bidID
        
        super.init()
    }
    
    func load() {
        DispatchQueue.main.async {
            self.containerViewController = FullscreenStaticContainerViewController(delegate: self, adm: self.adm)
            self.containerViewController?.loadHTML()
        }
    }
    
    func show(from viewController: UIViewController) {
        DispatchQueue.main.async {
            viewController.present(self.containerViewController!, animated: true)
            self.didShow()
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.impression()
            }
        }
    }
    
    func destroy() {
        containerViewController?.destroy()
    }
}

// MARK: - FullscreenStaticContainerViewControllerDelegate

extension CloudXDSPRewarded: FullscreenStaticContainerViewControllerDelegate {
    func didShow() {
        delegate?.didShow(rewarded: self)
    }
    
    func impression() {
        delegate?.impression(rewarded: self)
    }
    
    func didLoad() {
        delegate?.didLoad(rewarded: self)
    }
    
    func didFailToShow(error: Error) {
        delegate?.didFailToShow(rewarded: self, error: error)
    }
    
    func didClickFullAdd() {
        delegate?.click(rewarded: self)
    }
    
    func closeFullScreenAd() {
        delegate?.userReward(rewarded: self)
        delegate?.didClose(rewarded: self)
    }
}


