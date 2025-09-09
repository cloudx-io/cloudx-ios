//
//  CloudXDSPInterstitial.swift
//
//
//  Created by bkorda on 06.03.2024.
//
import WebKit
import SafariServices
import CloudXCore

final class CloudXDSPInterstitial: NSObject, AdapterInterstitial {
    var network: String { "DSP" }
    
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
            print("[CloudX][Interstitial] load() called with adm: \(self.adm.prefix(100))")
            self.containerViewController = FullscreenStaticContainerViewController(delegate: self, adm: self.adm)
            print("[CloudX][Interstitial] FullscreenStaticContainerViewController created: \(String(describing: self.containerViewController)))")
            self.containerViewController?.loadHTML()
            print("[CloudX][Interstitial] Called loadHTML() on containerViewController")
        }
    }
    
    func show(from viewController: UIViewController) {
        DispatchQueue.main.async {
            print("[CloudX][Interstitial] show() called, presenting containerViewController")
            viewController.present(self.containerViewController!, animated: true)
            self.didShow()
            print("[CloudX][Interstitial] didShow() called after present")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.impression()
                print("[CloudX][Interstitial] impression() called after 1s delay")
            }
        }
    }
    
    func destroy() {
        containerViewController?.destroy()
    }
}

// MARK: - FullscreenStaticContainerViewControllerDelegate

extension CloudXDSPInterstitial: FullscreenStaticContainerViewControllerDelegate {
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


