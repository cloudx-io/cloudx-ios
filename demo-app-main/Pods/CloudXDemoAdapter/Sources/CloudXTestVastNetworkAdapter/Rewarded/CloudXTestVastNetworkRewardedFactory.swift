//
//  CloudXTestVastNetworkRewardedFactory.swift
//  
//
//  Created by bkorda on 07.03.2024.
//

import UIKit
import CloudXCore

final class CloudXTestVastNetworkRewardedFactory: AdapterRewardedFactory {
    
    func create(adId: String, bidId: String, adm: String, extras: [String: String], delegate: CloudXCore.AdapterRewardedDelegate) -> CloudXCore.AdapterRewarded? {
        print("create CloudXTestVastNetworkRewardedFactory")
        return CloudXTestVastNetworkRewarded(adm: adm, bidID: bidId, delegate: delegate)
    }
    
    static func createInstance() -> CloudXTestVastNetworkRewardedFactory {
        CloudXTestVastNetworkRewardedFactory()
    }
    
}
