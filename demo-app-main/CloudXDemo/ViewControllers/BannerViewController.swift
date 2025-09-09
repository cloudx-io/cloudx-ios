//
//  BannerViewController.swift
//  CloudXDemo
//
//  Created by bkorda on 01.03.2024.
//

import UIKit
import CloudXCore
import ToastView
import SwiftUI
import Combine


class BannerViewController: BaseAdViewController {
    
    private let defaultPlacementBanner = "defaultBanner"
    private let demoPlacement = "MyDemoPlacement"
    private let defaultPlacementMrec = "defaultMREC"
    let logPrefix = "Banner"
    
    @IBOutlet weak var logContinerView: UIView!
    @IBOutlet weak var bannerPlaceView: UIView!
    @IBOutlet weak var bannerTypeView: UISegmentedControl!
    @IBOutlet weak var bannerContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var loadButton: UIButton!
    
    var bannerType: CloudXBannerType = .w320h50
    var cancellables: [AnyCancellable] = []
    let logDelegate = LogsDelegate(logStorage: LogStorageClass.shared)
    
    let standartHeightMaximum = 200
    let mrecHeightMaximum = 300
    
    var bannerViews: [CloudXBannerAdView] = []
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bannerTypeView.isHidden = appConfigModel?.layout.screens.banner.mrec.isEmpty ?? true && appConfigModel?.layout.screens.banner.standard.isEmpty ?? true
        updateNativeAddViewSize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !bannerViews.isEmpty {
            destroyBanner()
        }
    }
    
    @IBAction func loadBanner(_ sender: Any) {
        guard CloudX.shared.isInitialised else {
            ToastPresenter.show(title: "SDK is not initialized",
                                icon: UIImage(systemName: "exclamationmark.triangle"),
                                origin: self.view)
            return
        }
        if bannerViews.isEmpty {
            loadBanner()
        } else {
            destroyBanner()
        }
    }
    
    private func updateNativeAddViewSize() {
        var heightConstraint = 0
        if bannerType == .w320h50 {
            let nativeAddCount = appConfigModel?.layout.screens.banner.standard.count ?? 0
            heightConstraint = nativeAddCount * Int(bannerType.size.height)
            heightConstraint += (nativeAddCount + 1) * 8
            heightConstraint = heightConstraint <= standartHeightMaximum ? heightConstraint : standartHeightMaximum
        } else {
            let nativeAddCount = appConfigModel?.layout.screens.banner.mrec.count ?? 0
            heightConstraint = nativeAddCount * Int(bannerType.size.height)
            heightConstraint += (nativeAddCount + 1) * 8
            heightConstraint = heightConstraint <= mrecHeightMaximum ? heightConstraint : mrecHeightMaximum
        }
        self.bannerContainerHeight.constant = CGFloat(heightConstraint)
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func createBannerViews() {
        var placementsArray: [String] = []
        
        if bannerType == .w320h50 {
            appConfigModel?.layout.screens.banner.standard.forEach {
                logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Start loading banner with placement \($0.placementName)"))
                placementsArray.append($0.placementName) }
        } else {
            appConfigModel?.layout.screens.banner.mrec.forEach {
                logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Start loading mrec with placement \($0.placementName)"))
                placementsArray.append($0.placementName) }
        }
        
        for placement in placementsArray {
            guard let banner = CloudX.shared.createBanner(placement: placement, viewController: self, delegate: self) else { continue }
            banner.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                banner.widthAnchor.constraint(equalToConstant: self.bannerType.size.width),
                banner.heightAnchor.constraint(equalToConstant: self.bannerType.size.height),
            ])
            bannerViews.append(banner)
        }
        
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        bannerPlaceView.addSubview(scrollView)
        let stackView = UIStackView(arrangedSubviews: bannerViews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.axis = .vertical
        scrollView.addSubview(stackView)
        scrollView.contentInset = UIEdgeInsets.zero;
        NSLayoutConstraint.activate([
            
            scrollView.topAnchor.constraint(equalTo: bannerPlaceView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bannerPlaceView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: bannerPlaceView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: bannerPlaceView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
        ])
        
        for banner in bannerViews {
            banner.load()
        }
    }
    
    override func SDKinitialized() {
        
    }
    
    private func loadBanner() {
        createBannerViews()
        loadButton.setTitle("Stop", for: .normal)
    }
    
    private func destroyBanner() {
        for banner in bannerViews {
            banner.destroy()
        }
        bannerViews.removeAll()
        loadButton.setTitle("Load / Show", for: .normal)
    }
    
    @IBAction func changeBannerType(_ sender: UISegmentedControl) {
        destroyBanner()
        bannerType = CloudXBannerType(rawValue: sender.selectedSegmentIndex) ?? .w320h50
        updateNativeAddViewSize()
        
    }
}

extension BannerViewController: CloudXBannerDelegate {
    func closedByUserAction(on ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "did closed ByUserAction"))
        print("CloudX: SDK Callback >>> closedByUserAction \(ad) <<<")
        ad.destroy()
    }
    
    func didLoad(ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "did load"))
        
        print("CloudX: SDK Callback >>> didLoad \(ad) <<<")
    }
    
    func failToLoad(ad: CloudXCore.CloudXAd, with error: Error) {
        logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "fail to load with error \(error)"))
        
        print("CloudX: SDK Callback >>> failToLoad \(ad) with error \(error) <<<")
    }
    
    func didShow(ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message:
                                    """
                                    =============
                                    \(CloudX.shared.logsData["loopData"] ?? "") 
                                    =============
                                    CDP data: \(CloudX.shared.logsData["cdpData"] ?? "")
                                    =============
                                    \(CloudX.shared.logsData["bidderData"] ?? "")
                                    """
                                     ))
        
        print("CloudX: SDK Callback >>> didShow \(ad) <<<")
    }
    
    func failToShow(ad: CloudXCore.CloudXAd, with error: Error) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Banner fail to show with error \(error), \(CloudX.shared.logsData["bidderData"])"))
        
        print("CloudX: SDK Callback >>> failToShow \(ad) with error \(error) <<<")
    }
    
    func didHide(ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Banner did hide"))
        
        print("CloudX: SDK Callback >>> didHide \(ad) <<<")
    }
    
    func didClick(on ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Banner did click"))
        
        print("CloudX: SDK Callback >>> didClick \(ad) <<<")
    }
    
    func impression(on ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message:
                                    """
                                    -------------
                                    Tracking event:
                                    \(CloudX.shared.logsData["impData"] ?? "") 
                                    -------------
                                    """))
        
        print("CloudX: SDK Callback >>> impression \(ad) <<<")
    }
    
}

