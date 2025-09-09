//
//  CloudXMintegralRewardedFactory.swift
//
//
//  Created by bkorda on 18.07.2024.
//

import UIKit
import CloudXCore

final class CloudXMintegralRewardedFactory: AdapterRewardedFactory {
    
    func create(adId: String,
                bidId: String,
                adm: String,
                extras: [String : String],
                delegate: CloudXCore.AdapterRewardedDelegate) -> CloudXCore.AdapterRewarded? {
        
        guard let mtgPlacemetID = extras["placement_id"],
              let bidToken = extras["bid_id"] else { return nil }
        
        return CloudXMintegralRewarded(mtgPlacementID: mtgPlacemetID, mtgAdUnitID: adm, bidToken: bidToken, bidID: bidId, delegate: delegate)
    }
    
    static func createInstance() -> CloudXMintegralRewardedFactory {
        CloudXMintegralRewardedFactory()
    }
    
}
