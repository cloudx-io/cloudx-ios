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
    var gppString: String = ""
    var gppSid: String = ""
    var userTargeting: Bool = false
    
    /// When enabled, the full bid response JSON is printed to the console for QA inspection.
    /// This is a demo app-only feature and is NOT exposed in the SDK or public logs.
    var printBidResponse: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "DemoApp.PrintBidResponse")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DemoApp.PrintBidResponse")
            UserDefaults.standard.synchronize()
        }
    }
    
    private override init() {
        super.init()
    }
}