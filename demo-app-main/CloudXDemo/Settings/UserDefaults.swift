//
//  UserDefaults.swift
//  CloudXDemo
//
//  Created by bkorda on 01.03.2024.
//

import Foundation

protocol Settings {
    var appKey: String { get set }
    var initURL: String { get set }
    var mockLocalServer: Bool { get set }
    //Manual
    var gdpr: SettingsOption { get set }
    var age: SettingsOption { get set }
    var dns: SettingsOption { get set }
    
    var bannerPlacement: String { get set }
    var mrecPlacement: String { get set }
    var interstitialPlacement: String { get set }
    var rewardedPlacement: String { get set }
    var nativeSmallPlacement: String { get set }
    var nativeMediumPlacement: String { get set }
    
    var gdprApplies: SettingsOption { get set }
    var consentString: String? { get set }
    var usPrivacy: String? { get set }
    var userTargeting: Bool { get set }
    
    var hashedUserId: String? { get set }
    var userId: String? { get set }
    var keyValues: [String: Any]? { get set }
    var hashAlgo: String { get set }
    var userIdMiliseconds: Int { get set }
}

enum SettingsOption: String, CaseIterable {
    case `true`, `false`, none
    
    var intValue: Int {
        switch self {
        case .true:
            return 1
        case .false:
            return 0
        case .none:
            return -1
        }
    }
    
    var boolValue: Bool {
        switch self {
        case .true:
            return true
        case .false:
            return false
        case .none:
            return false
        }
    }
    
    init(intValue: Int) {
        switch intValue {
        case 1:
            self = .true
        case 0:
            self = .false
        default:
            self = .none
        }
    }
}

class UserDefaultsSettings: Settings {
    
    init() {
        if UserDefaults.standard.string(forKey: Keys.appKey.rawValue) == nil {
            self.appKey = "1c3589a1-rgto-4573-zdae-644c65074537"
            self.age = .none
            self.dns = .none
            self.gdpr = .none
            
            self.gdprApplies = .none
            
            self.bannerPlacement = "defaultBanner"
            self.mrecPlacement = "defaultMrec"
            self.interstitialPlacement = "defaultInterstitial"
            self.rewardedPlacement = "defaultRewarded"
            self.nativeSmallPlacement = "defaultNativeSmall"
            self.nativeMediumPlacement = "defaultNativeMedium"
            self.consentString = "CPokAsAPokAsABEACBENC7CgAP_AAH_AAAwIAAAAAAAA"
            self.usPrivacy = "1---"
            self.userTargeting = false
        }
        
        self.initURL = "https://provisioning.cloudx.io/sdk"
        
        if self.mockLocalServer {
            initURL = "http://localhost:6657"
        }
    }
    
    enum Keys: String {
        case appKey
        case initURL = "CloudXInitURL"
        case ifa = "ifa_config"
        case hashedUserId = "hashedUserId_config"
        case keyValues = "keyValues_config"
        case userId = "userId_config"
        case hashAlgo = "hashAlgo_config"
        case userIdMiliseconds = "userId_config_miliseconds"
        case bundle = "bundle_config"
        case mockLocalServer = "mock_preference"
        case gdpr = "gdpr_preference"
        case age = "age_preference"
        case dns = "dns_preference"
        case bannerPlacement = "banner_placement_preference"
        case mrecPlacement = "mrec_placement_preference"
        case interstitialPlacement = "interstitial_placement_preference"
        case rewardedPlacement = "rewarded_placement_preference"
        case nativeSmallPlacement = "native_small_placement_preference"
        case nativeMediumPlacement = "native_medium_placement_preference"
        case consentString = "IABTCF_TCString"
        case usPrivacy = "IABUSPrivacy_String"
        case gdprApplies = "IABTCF_gdprApplies"
        case userTargeting = "user_targeting_preference"
    }
    
    var appKey: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.appKey.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.appKey.rawValue)
        }
    }
    
    var initURL: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.initURL.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.initURL.rawValue)
        }
    }
    
    var hashedUserId: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.hashedUserId.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.hashedUserId.rawValue)
        }
    }
    
    var keyValues: [String: Any]? {
        get {
            return UserDefaults.standard.dictionary(forKey: Keys.keyValues.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.keyValues.rawValue)
        }
    }
    
    var userId: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.userId.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.userId.rawValue)
        }
    }
    
    var hashAlgo: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.hashAlgo.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.hashAlgo.rawValue)
        }
    }
    
    var userIdMiliseconds: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.userIdMiliseconds.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.userIdMiliseconds.rawValue)
        }
    }
    
    var ifa: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.ifa.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.ifa.rawValue)
        }
    }
    
    var bundle: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.bundle.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.bundle.rawValue)
        }
    }
    
    var mockLocalServer: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.mockLocalServer.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.mockLocalServer.rawValue)
        }
    }
    
    var gdpr: SettingsOption {
        get {
            guard let gdprString = UserDefaults.standard.string(forKey: Keys.gdpr.rawValue) else { return .none }
            return SettingsOption(rawValue: gdprString) ?? .none
        }
        set {
            if newValue == .none {
                UserDefaults.standard.removeObject(forKey: Keys.gdpr.rawValue)
            } else {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: Keys.gdpr.rawValue)
            }
        }
    }
    
    var age: SettingsOption {
        get {
            guard let ageString = UserDefaults.standard.string(forKey: Keys.age.rawValue) else { return .none }
            return SettingsOption(rawValue: ageString) ?? .none
        }
        set {
            if newValue == .none {
                UserDefaults.standard.removeObject(forKey: Keys.age.rawValue)
            } else {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: Keys.age.rawValue)
            }
        }
    }
    
    var dns: SettingsOption {
        get {
            guard let dnsString = UserDefaults.standard.string(forKey: Keys.dns.rawValue) else { return .none }
            return SettingsOption(rawValue: dnsString) ?? .none
        }
        set {
            if newValue == .none {
                UserDefaults.standard.removeObject(forKey: Keys.dns.rawValue)
            } else {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: Keys.dns.rawValue)
            }
        }
    }
    
    var bannerPlacement: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.bannerPlacement.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.bannerPlacement.rawValue)
        }
    }
    
    var mrecPlacement: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.mrecPlacement.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.mrecPlacement.rawValue)
        }
    }
    
    var interstitialPlacement: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.interstitialPlacement.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.interstitialPlacement.rawValue)
        }
    }
    
    var rewardedPlacement: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.rewardedPlacement.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.rewardedPlacement.rawValue)
        }
    }
    
    var nativeSmallPlacement: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.nativeSmallPlacement.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.nativeSmallPlacement.rawValue)
        }
    }
    
    var nativeMediumPlacement: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.nativeMediumPlacement.rawValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.nativeMediumPlacement.rawValue)
        }
    }
    
    var consentString: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.consentString.rawValue)
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: Keys.consentString.rawValue)
            } else {
                UserDefaults.standard.setValue(newValue, forKey: Keys.consentString.rawValue)
            }
        }
    }
    
    var usPrivacy: String? {
        get {
            return UserDefaults.standard.string(forKey: Keys.usPrivacy.rawValue)
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: Keys.usPrivacy.rawValue)
            } else {
                UserDefaults.standard.setValue(newValue, forKey: Keys.usPrivacy.rawValue)
            }
        }
    }
    
    var gdprApplies: SettingsOption {
        get {
            let gdprAppliesString = UserDefaults.standard.integer(forKey: Keys.gdprApplies.rawValue)
            return SettingsOption(intValue: gdprAppliesString)
        }
        set {
            if newValue == .none {
                UserDefaults.standard.removeObject(forKey: Keys.gdprApplies.rawValue)
            } else {
                UserDefaults.standard.setValue(newValue.intValue, forKey: Keys.gdprApplies.rawValue)
            }
        }
    }
            
    var userTargeting: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.userTargeting.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.userTargeting.rawValue)
        }
    }
}
