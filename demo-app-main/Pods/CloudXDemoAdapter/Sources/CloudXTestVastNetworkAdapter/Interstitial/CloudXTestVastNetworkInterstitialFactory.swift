//
//  CloudXTestVastNetworkInterstitialFactory.swift
//  
//
//  Created by bkorda on 07.03.2024.
//

import UIKit
import CloudXCore

public final class CloudXTestVastNetworkInterstitialFactory: AdapterInterstitialFactory {
    
    public func create(adId: String, bidId: String, adm: String, extras: [String: String], delegate: CloudXCore.AdapterInterstitialDelegate) -> CloudXCore.AdapterInterstitial? {
        
        return CloudXTestVastNetworkInterstitial(adm: adm, bidID: bidId, delegate: delegate)
    }
    
    public static func createInstance() -> CloudXTestVastNetworkInterstitialFactory {
        CloudXTestVastNetworkInterstitialFactory()
    }
    
}
