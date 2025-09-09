//
//  CloudXMintegralNativeFactory.swift
//
//
//  Created by bkorda on 27.05.2024.
//

import UIKit
import CloudXCore

final class CloudXMintegralNativeFactory: AdapterNativeFactory {
    
    func create(viewController: UIViewController, 
                type: CloudXCore.CloudXNativeTemplate,
                adId: String, bidId: String,
                adm: String,
                extras: [String : String],
                delegate: CloudXCore.AdapterNativeDelegate) -> CloudXCore.AdapterNative? {
        
        guard let mtgPlacemetID = extras["placement_id"],
              let bidToken = extras["bid_id"] else { return nil }
        
        return CloudXMintegralNative(mtgPlacementID: mtgPlacemetID, mtgAdUnitID: adm, bidToken: bidToken, type: type, viewController: viewController, delegate: delegate)
    }
    
    static func createInstance() -> CloudXMintegralNativeFactory {
        CloudXMintegralNativeFactory()
    }
    
}
