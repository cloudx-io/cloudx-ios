//
//  RewardedViewContoller.swift
//  CloudXDemo
//
//  Created by bkorda on 07.03.2024.
//

import UIKit
import CloudXCore
import ToastView
import SwiftUI
import Combine

class RewardedViewContoller: BaseAdViewController {
    
    let logPrefix = "Rewarded"
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var logContinerView: UIView!
    var rewarded: CloudXRewardedInterstitial?
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
        
        createRewared()
    }
    
    @IBAction func loadAd(_ sender: Any) {
        guard CloudX.shared.isInitialised else {
            ToastPresenter.show(title: "SDK is not initialized",
                                icon: UIImage(systemName: "exclamationmark.triangle"),
                                origin: self.view)
            return
        }
        
        rewarded?.load()
    }
    
    @IBAction func showAd(_ sender: Any) {
        guard let rewarded, CloudX.shared.isInitialised else {
            logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "Ad is not created, SDK is not initialized"))
            return
        }
        rewarded.show(from: self)
    }
    
    override func SDKinitialized() {
        createRewared()
    }
    
    private func createRewared() {
        if CloudX.shared.isInitialised && rewarded == nil {
            let placement = appConfigModel?.layout.screens.rewarded.def?.first?.placementName ?? settings.rewardedPlacement
            guard let rewarded = CloudX.shared.createRewarded(placement: placement, delegate: self) else {
                logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "Can't create rewarded with placement: \(placement)"))
                return
            }
            self.rewarded = rewarded
            logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Start loading ad with placement \(placement)"))
        }
    }

}

extension RewardedViewContoller: CloudXRewardedDelegate {
    func closedByUserAction(on ad: any CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> closedByUserAction \(ad) <<<")
    }
    
    func userRewarded(ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> userRewarded \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "user reward"))
    }

    func rewardedVideoStarted(ad: CloudXCore.CloudXAd) {}
    
    func rewardedVideoCompleted(ad: CloudXCore.CloudXAd) {}
    
    func didLoad(ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> didLoad \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Rewarder ad did load, \(CloudX.shared.logsData["bidderData"])"))
        showButton.isEnabled = true
    }
    
    func failToLoad(ad: CloudXCore.CloudXAd, with error: Error) {
        print("CloudX: SDK Callback >>> failToLoad \(ad) with error \(error) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Rewarder ad fail to load with error \(error), \(CloudX.shared.logsData["bidderData"])"))
    }
    
    func didShow(ad: CloudXCore.CloudXAd) {
        print("CloudX: SDK Callback >>> didShow \(ad) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Rewarded ad did show with data \(CloudX.shared.logsData["bidderData"])"))
    }
    
    func failToShow(ad: CloudXCore.CloudXAd, with error: Error) {
        print("CloudX: SDK Callback >>> failToShow \(ad) with error \(error) <<<")
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Rewarder ad fail to show with error \(error), \(CloudX.shared.logsData["bidderData"])"))
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
