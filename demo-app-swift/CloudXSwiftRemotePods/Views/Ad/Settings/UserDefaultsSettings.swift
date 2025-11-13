//
//  UserDefaultsSettings.swift
//  CloudXSwiftRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

import Foundation

class UserDefaultsSettings: NSObject {
    
    static let shared = UserDefaultsSettings()
    
    var appKey: String = ""
    var SDKinitURL: String = ""
    var bannerPlacement: String = ""
    var mrecPlacement: String = ""
    var interstitialPlacement: String = ""
    var rewardedPlacement: String = ""
    var nativeSmallPlacement: String = ""
    var nativeMediumPlacement: String = ""
    var consentString: String = ""
    var usPrivacyString: String = ""
    var userTargeting: Bool = false
    
    private override init() {
        super.init()
    }
}