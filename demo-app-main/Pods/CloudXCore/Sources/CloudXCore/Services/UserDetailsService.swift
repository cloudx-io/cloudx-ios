//
//  UserDetailsService.swift
//  cloudexchange.sdk.ios.core
//
//  Created by Xenoss on 29.04.2025.
//
import Foundation

public final class UserDetailsService {
    
    public var hashedUserID: String
    public var hashedKeyValue: (key: String, value: String)
    public var keyValue: (key: String, value: String)
    public var bidderKeyValue: (bidder: String, key: String, value: String)
    
    init() {
        self.hashedUserID = ""
        self.hashedKeyValue = (key: "", value: "")
        self.keyValue = (key: "", value: "")
        self.bidderKeyValue = (bidder: "", key: "", value: "")
    }
    
    public func setBidderKeyValue(bidder: String, key: String, value: String) {
        self.bidderKeyValue = (bidder: bidder, key: key, value: value)
    }
    
    public func setKeyValue(key: String, value: String) {
        self.keyValue = (key: key, value: value)
    }
    
    public func setHashedKeyValue(key: String, value: String) {
        self.hashedKeyValue = (key: key, value: value)
    }
    
    public func setHashedUserID(_ hashedUserID: String) {
        self.hashedUserID = hashedUserID
    }
}
