//
//  CloudXPrivacy.swift
//  CloudXCore
//
//  Created by bkorda on 29.02.2024.
//

import Foundation

///Fill this object to respect user privacy consent.
public class CloudXPrivacy: NSObject {
    
    ///Checks if user has set consent for information sharing.
    /// - Returns: `true`if user has consent for information sharing.. `false` if user has not consented information sharing or the value has not been set.
    @objc public static var hasUserConsent: Bool = false {
        didSet {
            isUserConsentSet = true
        }
    }
    
    ///Checks if the user is age-restricted.
    ///- Returns: `true`  if the user is age-restricted. `false`  if the user is not age-restricted or the age-restriction value has not been set.
    @objc public static var isAgeRestrictedUser: Bool = false {
        didSet {
            isAgeRestrictedUserSet = true
        }
    }
    
    ///Checks if the user has opted out of the sale of their personal information.
    ///- Returns: `true` if the user opted out of the sale of their personal information. `false` if the user opted in to the sale of their personal information or the value has not been set .
    @objc public static var isDoNotSell: Bool = false {
        didSet {
            isDoNotSellSet = true
        }
    }
    
    ///Checks if the user has opted out of the sale of their personal information.
    ///- Returns: `true` if user has set a value of consent for information sharing.
    @objc public private(set) static var isUserConsentSet: Bool = false
    
    ///Checks if user has set its age restricted settings.
    ///- Returns: `true` if user has set its age restricted settings.
    @objc public private(set) static var isAgeRestrictedUserSet: Bool = false
    
    ///Checks if the user has set the option to sell their personal information.
    ///- Returns: `true` if user has chosen an option to sell their personal information.
    @objc public private(set) static var isDoNotSellSet: Bool = false
    
    private override init() {}
    
    //https://github.com/InteractiveAdvertisingBureau/USPrivacy/blob/master/CCPA/US%20Privacy%20String.md
    ///Returns IAB US Privacy string.
    ///- Returns:
    @objc public static var usPrivacyString: String? {
        return UserDefaults.standard.string(forKey: "IABUSPrivacy_String")
    }
    
    static var tcfString: String? {
        return UserDefaults.standard.string(forKey: "IABTCF_TCString")
    }
    
    // 1 GDPR applies in current context
    // 0 - GDPR does not apply in current context
    // Unset - undetermined (default before initialization)
    static var gdprApplies: Bool? {
        let gdprAppliesKey = "IABTCF_gdprApplies"
        let value = UserDefaults.standard.integer(forKey: gdprAppliesKey)
        switch value {
        case 1:
            return true
        case 0:
            // Check if the key actually exists, as integer(forKey:) returns 0 if the key is not found.
            return UserDefaults.standard.object(forKey: gdprAppliesKey) != nil ? false : nil
        default:
            return nil
        }
    }
    
}
