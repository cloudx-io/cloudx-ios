//
//  CloudXTargeting.swift
//  CloudXCore
//
//  Created by bkorda on 18.06.2024.
//

import Foundation

///Fill this improve user targeting.
public final class CloudXTargeting {
    
    ///Gender, where “M” = male, “F” = female, “O” = known to be
    ///other (i.e., omitted is unknown).
    public enum CloudXGender: String {
        case male = "M"
        case female = "F"
        case other = "O"
    }
    
    ///Shared instance of `CloudXTargeting`.
    public static var shared = CloudXTargeting()
    
    private init() {}
    
    ///Exchange-specific ID for the user. At least one of id or
    public var userID: String?
    
    ///Set the user's age.
    public var age: Int?
    
    ///Year of birth as a 4-digit integer.
    public var yob: Int?
    
    ///Gender of the user
    public var gender: CloudXGender?
    
    ///List of keywords, interests, or intent.
    public var keywords: [String]?
    
    ///Additional user data.
    public var data: [String : String]?
}

extension CloudXTargeting.CloudXGender: Encodable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
}
