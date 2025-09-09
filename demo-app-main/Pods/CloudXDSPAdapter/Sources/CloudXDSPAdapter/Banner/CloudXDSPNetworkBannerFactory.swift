//
//  CloudXDSPBannerFactory.swift
//  
//
//  Created by bkorda on 06.03.2024.
//

import UIKit
import CloudXCore

final class CloudXDSPBannerFactory: AdapterBannerFactory {
    
    func create(viewController: UIViewController, type: CloudXCore.CloudXBannerType, adId: String, bidId: String, adm: String, hasClosedButton: Bool, extras: [String: String], delegate: CloudXCore.AdapterBannerDelegate) -> CloudXCore.AdapterBanner? {
        
        return CloudXDSPBanner(adm: adm, hasClosedButton: hasClosedButton, type: type, viewController: viewController, delegate: delegate)
    }
    
    static func createInstance() -> CloudXDSPBannerFactory {
        CloudXDSPBannerFactory()
    }
    
}
