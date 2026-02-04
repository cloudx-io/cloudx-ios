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
    var bannerAdUnitId: String = ""
    var mrecAdUnitId: String = ""
    var interstitialAdUnitId: String = ""
    var rewardedAdUnitId: String = ""
    var nativeSmallAdUnitId: String = ""
    var nativeMediumAdUnitId: String = ""
    var consentString: String = ""
    var usPrivacyString: String = ""
    var userTargeting: Bool = false
    
    private override init() {
        super.init()
    }
}