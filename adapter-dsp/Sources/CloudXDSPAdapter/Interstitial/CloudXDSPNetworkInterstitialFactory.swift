//
//  CloudXDSPInterstitialFactory.swift
//  
//
//  Created by bkorda on 07.03.2024.
//

import UIKit
import CloudXCore

final class CloudXDSPInterstitialFactory: AdapterInterstitialFactory {
    
    func create(adId: String, bidId: String, adm: String, extras: [String: String], delegate: CloudXCore.AdapterInterstitialDelegate) -> CloudXCore.AdapterInterstitial? {
        
        return CloudXDSPInterstitial(adm: adm, bidID: bidId, delegate: delegate)
    }
    
    static func createInstance() -> CloudXDSPInterstitialFactory {
        CloudXDSPInterstitialFactory()
    }
    
}
