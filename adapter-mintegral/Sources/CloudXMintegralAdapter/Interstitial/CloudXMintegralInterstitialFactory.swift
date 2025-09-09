//
//  CloudXMintegrakInterstitialFactory.swift
//
//
//  Created by bkorda on 18.07.2024.
//

import UIKit
import CloudXCore

final class CloudXMintegralInterstitialFactory: AdapterInterstitialFactory {
    
    func create(adId: String,
                bidId: String,
                adm: String,
                extras: [String : String],
                delegate: CloudXCore.AdapterInterstitialDelegate) -> CloudXCore.AdapterInterstitial? {
        
        guard let mtgPlacemetID = extras["placement_id"],
              let bidToken = extras["bid_id"] else { return nil }
        
        return CloudXMintegralInterstitial(mtgPlacementID: mtgPlacemetID, mtgAdUnitID: adm, bidToken: bidToken, bidID: bidId, delegate: delegate)
    }
    
    static func createInstance() -> CloudXMintegralInterstitialFactory {
        CloudXMintegralInterstitialFactory()
    }
    
}
