//
//  CloudXTestVastNetworkNative.swift
//
//
//  Created by bkorda on 06.04.2024.
//

import WebKit
import SafariServices
import CloudXCore

class CloudXTestVastNetworkNative: NSObject, AdapterNative {
    weak var delegate: CloudXCore.AdapterNativeDelegate?
    
    var timeout: Bool = false
    
    lazy var nativeView: UIView? = {
        type.view as? UIView
    }()
    
    var sdkVersion: String { CloudX.shared.sdkVersion }
    
    private let nativeAdData: NativeAdData?
    private let viewController: UIViewController
    private let type: CloudXNativeTemplate
    
    init(adm: String, type: CloudXNativeTemplate, viewController: UIViewController, delegate: AdapterNativeDelegate?) {
        self.delegate = delegate
        self.type = type
        self.nativeAdData = try? JSONDecoder().decode(NativeAdData.self, from: adm.data(using: .utf8)!)
        self.viewController = viewController
        
        super.init()
    }
    
    func load() {
        Task.detached { @MainActor in
            guard let nativeAdData = self.nativeAdData else {
                self.delegate?.failToLoad(native: self, error: CloudXDemoAdapterError.invalidAdm)
                return
            }
            var view = self.nativeView as? CloudXBaseNativeView
            
            if let mainImageURL = self.nativeAdData?.mainImgURL {
                let (data, response) = try await URLSession.shared.data(from: URL(string: mainImageURL)!)
                view?.mainImage = UIImage(data: data)
            }
            
            if let iconURL = self.nativeAdData?.appIconURL {
                let (data, response) = try await URLSession.shared.data(from: URL(string: iconURL)!)
                view?.appIcon = UIImage(data: data)
            }
            
            
            view?.title = self.nativeAdData?.title
            view?.descriptionText = self.nativeAdData?.description
            view?.callToActionText = self.nativeAdData?.ctatext
            
            view?.cta = { @MainActor [weak self] in
                guard let self else { return }
                let url = self.nativeAdData?.ctaLink
                let safary = SFSafariViewController(url: URL(string: url!)!)
                self.viewController.present(safary, animated: true)
                
                self.delegate?.click(native: self)
            }
            
            view?.close = { [weak self] in
                guard let self else { return }
                self.delegate?.close(native: self)
            }
            
            self.delegate?.didLoad(native: self)
            self.delegate?.impression(native: self)
        }
        
    }
    
    func destroy() {
        
    }

}
