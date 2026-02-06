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
    
    /// Hashed User ID for SDK initialization (persisted to UserDefaults)
    var hashedUserId: String? {
        get {
            return UserDefaults.standard.string(forKey: "DemoApp.HashedUserId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DemoApp.HashedUserId")
            UserDefaults.standard.synchronize()
        }
    }
    
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