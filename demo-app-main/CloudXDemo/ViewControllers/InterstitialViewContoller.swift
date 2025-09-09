//
//  InterstitialViewContoller.swift
//  CloudXDemo
//
//  Created by bkorda on 07.03.2024.
//

import UIKit
import CloudXCore
import ToastView
import SwiftUI
import Combine

class InterstitialViewContoller: BaseAdViewController {
    
    private let defaultPlacement = "defaultInterstitial"
    let logPrefix = "Interstitial"
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var logContinerView: UIView!
    var interstitial: CloudXInterstitial?
    var cancellables: [AnyCancellable] = []
    let logDelegate = LogsDelegate(logStorage: LogStorageClass.shared)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logView = LogView(logDelegate: logDelegate)
        let logViewHost = UIHostingController(rootView: logView)
        logViewHost.view.translatesAutoresizingMaskIntoConstraints = false

        logContinerView.addSubview(logViewHost.view)
        NSLayoutConstraint.activate([
            logViewHost.view.topAnchor.constraint(equalTo: logContinerView.topAnchor),
            logViewHost.view.bottomAnchor.constraint(equalTo: logContinerView.bottomAnchor),
            logViewHost.view.leadingAnchor.constraint(equalTo: logContinerView.leadingAnchor),
            logViewHost.view.trailingAnchor.constraint(equalTo: logContinerView.trailingAnchor),
        ])
        createInterstitial()
    }
    
    @IBAction func loadAd(_ sender: Any) {
        guard CloudX.shared.isInitialised else {
            ToastPresenter.show(title: "SDK is not initialized",
                                icon: UIImage(systemName: "exclamationmark.triangle"),
                                origin: self.view)
            return
        }
        
        interstitial?.load()
    }
    
    @IBAction func showAd(_ sender: Any) {
        guard let interstitial, CloudX.shared.isInitialised else {
            logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "Ad is not created, SDK is not initialized"))
            return
        }
        
        interstitial.show(from: self)
    }
    
    override func SDKinitialized() {
        createInterstitial()
    }
    
    private func createInterstitial() {
        if CloudX.shared.isInitialised && interstitial == nil {
            let placement = appConfigModel?.layout.screens.interstitial.def?.first?.placementName ?? settings.interstitialPlacement
            guard let interstitial = CloudX.shared.createInterstitial(placement: placement, delegate: self) else {
                logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "Can't create interstitial with placement: \(placement)"))
                return
            }
            self.interstitial = interstitial
            logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Start loading ad with placement \(placement)"))
        }
    }

}

extension InterstitialViewContoller: CloudXInterstitialDelegate {
    func closedByUserAction(on ad: any CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> closedByUserAction \(ad) <<<")
    }
    
    func didLoad(ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> didLoad \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Interstitial ad did load with data \(CloudX.shared.logsData["bidderData"])"))
    }
    
    func failToLoad(ad: CloudXCore.CloudXAd, with error: Error) {
        print("CloudX: SDK Callback >>> failToLoad \(ad) with error \(error) <<<")
        logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "fail to load with \(error.localizedDescription)"))
    }
    
    func didShow(ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> didShow \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Interstitial ad did show with data \(CloudX.shared.logsData["bidderData"])"))
    }
    
    func failToShow(ad: CloudXCore.CloudXAd, with error: Error) {
        print("CloudX: SDK Callback >>> failToShow \(ad) with error \(error) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Interstitial ad fail to show with error \(error), \(CloudX.shared.logsData["bidderData"])"))
        
    }
    
    func didHide(ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> didHide \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "did hide"))
    }
    
    func didClick(on ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> didClick \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "did click"))
    }
    
    func impression(on ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> impression \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "impression"))
    }
    
    
}
