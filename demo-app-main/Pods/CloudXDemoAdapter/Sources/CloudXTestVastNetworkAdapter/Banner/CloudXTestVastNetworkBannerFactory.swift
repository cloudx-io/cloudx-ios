//
//  CloudXTestVastNetworkBannerFactory.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit
import CloudXCore

final class CloudXTestVastNetworkBannerFactory: AdapterBannerFactory {
    
    func create(viewController: UIViewController, type: CloudXCore.CloudXBannerType, adId: String, bidId: String, adm: String, hasClosedButton: Bool, extras: [String: String], delegate: CloudXCore.AdapterBannerDelegate) -> CloudXCore.AdapterBanner? {
        
        return CloudXTestVastNetworkBanner(adm: adm, hasClosedButton: hasClosedButton, type: type, viewController: viewController, delegate: delegate)
    }
    
    static func createInstance() -> CloudXTestVastNetworkBannerFactory {
        CloudXTestVastNetworkBannerFactory()
    }
    
}
