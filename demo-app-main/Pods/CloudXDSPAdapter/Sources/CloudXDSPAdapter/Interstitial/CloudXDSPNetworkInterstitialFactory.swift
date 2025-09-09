//
//  CloudXDSPInterstitialFactory.swift
//  
//
//  Created by bkorda on 07.03.2024.
//

import UIKit
import CloudXCore

public final class CloudXDSPInterstitialFactory: AdapterInterstitialFactory {
    
    public func create(adId: String, bidId: String, adm: String, extras: [String: String], delegate: CloudXCore.AdapterInterstitialDelegate) -> CloudXCore.AdapterInterstitial? {
        
        return CloudXDSPInterstitial(adm: adm, bidID: bidId, delegate: delegate)
    }
    
    public static func createInstance() -> CloudXDSPInterstitialFactory {
        CloudXDSPInterstitialFactory()
    }
    
}
