//
//  CloudXMintegralBannerFactory.swift
//
//
//  Created by bkorda on 18.07.2024.
//

import UIKit
import CloudXCore

final class CloudXMintegralBannerFactory: AdapterBannerFactory {
    func create(viewController: UIViewController, type: CloudXCore.CloudXBannerType, adId: String, bidId: String, adm: String, hasClosedButton: Bool, extras: [String : String], delegate: any CloudXCore.AdapterBannerDelegate) -> (any CloudXCore.AdapterBanner)? {
        
        guard let mtgPlacemetID = extras["placement_id"],
              let bidToken = extras["bid_id"] else { return nil }   
        
        return CloudXMintegralBanner(mtgPlacementID: mtgPlacemetID, mtgUnitID: adm, bidToken: bidToken, type: type, viewController: viewController, delegate: delegate)
    }
    
    static func createInstance() -> CloudXMintegralBannerFactory {
        CloudXMintegralBannerFactory()
    }
    
}
