//
//  SKAdNetworkService.swift
//
//
//  Created by Bohdan Korda on 09.07.2024.
//

import Foundation
import StoreKit

///If you use SKAD Network you can find helpful information here
public protocol SKAdNetworkConstants {
    ///Returns array of SKAD Network identifiers from `info.plist` file.
    var skadPlistIds: [String]? { get }
    
    ///Array of supported SKAD Network versions
    var versions: [String] { get }
    
    ///Source app identifier
    var sourceApp: String { get }
}

final class SKAdNetworkService: SKAdNetworkConstants {
    private let systemVersion: String
    
    public var sourceApp: String {
        SystemInformation.shared.appBundleIdentifier
    }
    
    public var versions: [String] {
        let everySkanVersions = ["2.0", "2.1", "2.2", "3.0", "4.0"]
        if systemVersion.versionCompare("16.1") == .orderedDescending || systemVersion.versionCompare("16.1") == .orderedSame {
            return everySkanVersions
        } else if systemVersion.versionCompare("14.6") == .orderedDescending || systemVersion.versionCompare("14.6") == .orderedSame {
            return everySkanVersions.dropLast()
        } else if systemVersion.versionCompare("14.5") == .orderedDescending || systemVersion.versionCompare("14.5") == .orderedSame {
            return everySkanVersions.dropLast(2)
        } else if systemVersion.versionCompare("14.0") == .orderedDescending || systemVersion.versionCompare("14.0") == .orderedSame {
            return everySkanVersions.dropLast(3)
        } else {
            return []
        }
    }
    
    public lazy var skadPlistIds: [String]? = {
        (Bundle.main.object(forInfoDictionaryKey: CloudXPlistKeys.skadPlistIdKey) as? [[String: String]])?
            .compactMap { $0.first?.value }
    }()
    
    public init(systemVersion: String) {
        self.systemVersion = systemVersion
    }
}

extension SKAdNetworkConstants {
    ///Returns filled object for bid request.
    var skadRequestParameters: SKAdRequestParameters {
        return SKAdRequestParameters(versions: self.versions, skadIDs: self.skadPlistIds ?? [], sourceApp: self.sourceApp)
    }
}
