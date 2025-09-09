//
//  CloudXDSPInitializer.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit
import CloudXCore

final class CloudXDSPInitializer: AdNetworkInitializer  {
    static var isInitialized: Bool = false
    
    func initialize(config: CloudXCore.BidderConfig?) async throws -> Bool {
        return true
    }
    
    static func createInstance() -> CloudXDSPInitializer {
        return CloudXDSPInitializer()
    }

}
