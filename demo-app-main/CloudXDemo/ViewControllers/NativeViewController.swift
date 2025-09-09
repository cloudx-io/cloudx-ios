//
//  NativeViewController.swift
//  CloudXDemo
//
//  Created by bkorda on 10.04.2024.
//

import UIKit
import CloudXCore
import ToastView
import SwiftUI
import Combine

class NativeViewController: BaseAdViewController {
     
    let logPrefix = "Native"
    @IBOutlet weak var nativeContinerView: UIView!
    @IBOutlet weak var logContinerView: UIView!
    
    @IBOutlet weak var nativeContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var nativeTypeView: UISegmentedControl!
    
    var nativeType: CloudXNativeTemplate = .small
    var native: CloudXNativeAdView?
    var cancellables: [AnyCancellable] = []
    let logDelegate = LogsDelegate(logStorage: LogStorageClass.shared)
    let smallHeightMaximum = 200
    let mediumHeightMaximum = 300
    
    var nativeViews: [CloudXNativeAdView] = []
    
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
        nativeTypeView.isHidden = appConfigModel?.layout.screens.native.small.isEmpty ?? true && appConfigModel?.layout.screens.native.medium.isEmpty ?? true
        updateNativeAddViewSize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !nativeViews.isEmpty {
            destroyNative()
        }
    }
    
    @IBAction func loadNative(_ sender: Any) {
        guard CloudX.shared.isInitialised else {
            ToastPresenter.show(title: "SDK is not initialized",
                                icon: UIImage(systemName: "exclamationmark.triangle"),
                                origin: self.view)
            return
        }
        if nativeViews.isEmpty {
            loadNative()
        } else {
            destroyNative()
        }
    }
    
    override func SDKinitialized() {
        
    }
    
    private func loadNative() {
        createNativeViews()
        loadButton.setTitle("Stop", for: .normal)
    }
    
    private func updateNativeAddViewSize() {
        var heightConstraint = 0
        if nativeType == .medium {
            let nativeAddCount = appConfigModel?.layout.screens.native.medium.count ?? 0
            heightConstraint = nativeAddCount * Int(nativeType.size.height)
            heightConstraint += (nativeAddCount + 1) * 8
            heightConstraint = heightConstraint <= mediumHeightMaximum ? heightConstraint : mediumHeightMaximum
        } else {
            let nativeAddCount = appConfigModel?.layout.screens.native.small.count ?? 0
            heightConstraint = nativeAddCount * Int(nativeType.size.height)
            heightConstraint += (nativeAddCount + 1) * 8
            heightConstraint = heightConstraint <= smallHeightMaximum ? heightConstraint : smallHeightMaximum
        }
        self.nativeContainerHeight.constant = CGFloat(heightConstraint)
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func destroyNative() {
        for native in nativeViews {
            native.destroy()
        }
        nativeViews.removeAll()
        loadButton.setTitle("Load / Show", for: .normal)
    }
    
    func createNativeViews() {
        var placementsArray: [String] = []
        if nativeType == .medium {
            appConfigModel?.layout.screens.native.medium.forEach {
                logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Start loading medium native with placement \($0.placementName)"))
                placementsArray.append($0.placementName) }
        } else {
            appConfigModel?.layout.screens.native.small.forEach {
                logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Start loading small native with placement \($0.placementName)"))
                placementsArray.append($0.placementName) }
        }
        
        for placement in placementsArray {
            guard let native = CloudX.shared.createNativeAd(placement: placement, viewController: self, delegate: self) else {
                logDelegate.logs.append(.init(type: .error, prefix: logPrefix, message: "Can't create native ad with placement: \(placement)"))
                continue }
            native.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            native.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                native.widthAnchor.constraint(equalToConstant: self.nativeType.size.width),
                native.heightAnchor.constraint(equalToConstant: self.nativeType.size.height),
            ])
            nativeViews.append(native)
        }
        
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        nativeContinerView.addSubview(scrollView)
        let stackView = UIStackView(arrangedSubviews: nativeViews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.axis = .vertical
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            
            scrollView.topAnchor.constraint(equalTo: nativeContinerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: nativeContinerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: nativeContinerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: nativeContinerView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
        ])
        
        
        
        for native in nativeViews {
            native.load()
        }
    }
    
    @IBAction func changeNativeType(_ sender: UISegmentedControl) {
        destroyNative()
        switch sender.selectedSegmentIndex {
        case 0:
            nativeType = .small
        case 1:
            nativeType = .medium
        default:
            nativeType = .small
        }
        updateNativeAddViewSize()
    }
}

extension NativeViewController: CloudXNativeDelegate {
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
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Native ad did show with data: \(CloudX.shared.logsData["bidderData"])"))
        
        print("CloudX: SDK Callback >>> didShow \(ad) <<<")
    }
    
    func failToShow(ad: CloudXCore.CloudXAd, with error: Error) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Native ad fail to show with error \(error), \(CloudX.shared.logsData["bidderData"])"))
        
        print("CloudX: SDK Callback >>> failToShow \(ad) with error \(error) <<<")
    }
    
    func didHide(ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "did hide"))
        
        print("CloudX: SDK Callback >>> didHide \(ad) <<<")
    }
    
    func didClick(on ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "did click"))
        
        print("CloudX: SDK Callback >>> didClick \(ad) <<<")
    }
    
    func impression(on ad: CloudXCore.CloudXAd) {
        logDelegate.logs.append(.init(type: .info, prefix: logPrefix, message: "Native ad impression with data: \(CloudX.shared.logsData["bidderData"])"))
        
        print("CloudX: SDK Callback >>> impression \(ad) <<<")
    }
    
    
}

