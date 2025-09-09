//
//  CloudXTestVastNetworkInterstitial.swift
//
//
//  Created by bkorda on 06.03.2024.
//
import WebKit
import SafariServices
import CloudXCore

final class CloudXTestVastNetworkInterstitial: NSObject, AdapterInterstitial {
    var network: String { "TestVastNetwork" }
    
    weak var delegate: AdapterInterstitialDelegate?
    
    var isReady: Bool {
        return containerViewController != nil
    }
    
    var sdkVersion: String {
        return CloudX.shared.sdkVersion
    }
    let bidID: String
    
    private let adm: String
    private var containerViewController: FullscreenStaticContainerViewController!
    
    // MARK: - Init
    
    deinit {
        print("AAA deinit \(self)")
    }
    
    init(adm: String, bidID: String, delegate: AdapterInterstitialDelegate?) {
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

extension CloudXTestVastNetworkInterstitial: FullscreenStaticContainerViewControllerDelegate {
    func didShow() {
        delegate?.didShow(interstitial: self)
    }
    
    func impression() {
        delegate?.impression(interstitial: self)
    }
    
    func didLoad() {
        delegate?.didLoad(interstitial: self)
    }
    
    func didFailToShow(error: Error) {
        delegate?.didFailToShow(interstitial: self, error: error)
    }
    
    func didClickFullAdd() {
        delegate?.click(interstitial: self)
    }
    
    func closeFullScreenAd() {
        delegate?.didClose(interstitial: self)
    }
}


