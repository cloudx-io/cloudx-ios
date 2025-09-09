//
//  CloudXMintegralInitializer.swift
//
//
//  Created by bkorda on 17.07.2024.
//

import UIKit
import CloudXCore
import MTGSDK

final class CloudXMintegralInitializer: AdNetworkInitializer  {
    static var isInitialized: Bool = false
    static var sdkVersion: String = { MTGSDKVersion }()
    
    func initialize(config: CloudXCore.BidderConfig?) async throws -> Bool {
        let mtgsdk = MTGSDK.sharedInstance()
        guard let appID = config?.initData["appID"],
              let appKey = config?.initData["appKey"] else {
            return false
        }
        
        if let classType = NSClassFromString("MTGSDK") {
            let selector = NSSelectorFromString("setChannelFlag:")
            if classType.responds(to: selector) {
                classType.perform(selector, with: "Y+H6DFttYrPQYcIAicKwJQKQYrN=", afterDelay: 0)
            }
        }
        
        await MainActor.run {
            MTGSDK.sharedInstance().consentStatus = CloudXPrivacy.hasUserConsent
            MTGSDK.sharedInstance().doNotTrackStatus = CloudXPrivacy.isDoNotSell
            MTGSDK.sharedInstance().coppa = CloudXPrivacy.isAgeRestrictedUser ? MTGBool.yes : (CloudXPrivacy.isAgeRestrictedUserSet ? MTGBool.no : MTGBool.unknown)
            mtgsdk.setAppID(appID, apiKey: appKey)
        }
        return true
    }
    
    static func createInstance() -> CloudXMintegralInitializer {
        return CloudXMintegralInitializer()
    }
    
}
