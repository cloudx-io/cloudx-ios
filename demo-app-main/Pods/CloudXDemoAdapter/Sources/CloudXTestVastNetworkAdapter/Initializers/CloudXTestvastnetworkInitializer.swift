//
//  CloudXTestvastnetworkInitializer.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit
import CloudXCore

public final class CloudXTestVastNetworkInitializer: NSObject, AdNetworkInitializer  {
    public static var isInitialized: Bool = false
    
    public required override init() {}

    public func initialize(config: CloudXCore.BidderConfig?) async throws -> Bool {
        return true
    }
    
    public static func createInstance() -> CloudXTestVastNetworkInitializer {
        return CloudXTestVastNetworkInitializer()
    }

}
