//
//  AdNetworkInitializer.swift
//  
//
//  Created by bkorda on 01.03.2024.
//

import Foundation

// MARK: - Swift-native protocol for ad network initialization
public protocol AdNetworkInitializer: AnyObject, Instanciable {
    /// Flag to indicate if the ad network SDK is initialized.
    static var isInitialized: Bool { get }

    /// Swift-only async/throws initializer
    func initialize(
        config: BidderConfig?
    ) async throws -> Bool
}

// MARK: - Objective-C compatible protocol for ad network initialization
@objc public protocol AdNetworkInitializerObjC: AnyObject, Instantiable {
    @objc optional func initialize(
        config: ObjCBidderConfigProtocol?,
        completion: @escaping (Bool, NSError?) -> Void
    )
    @objc static var isInitialized: Bool { get }
}

// MARK: - Type-Erased Wrappers for Ad Network Initializer
protocol UnifiedAdNetworkInitializer {
    func initialize(config: Any?, completion: @escaping (Bool, Error?) -> Void)
    var isInitialized: Bool { get }
}

struct SwiftUnifiedAdNetworkInitializer: UnifiedAdNetworkInitializer {
    let instance: AdNetworkInitializer.Type

    func initialize(config: Any?, completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                let initializer = instance.createInstance() as! AdNetworkInitializer
                let result = try await initializer.initialize(config: config as? BidderConfig)
                completion(result, nil)
            } catch {
                completion(false, error)
            }
        }
    }

    var isInitialized: Bool {
        return instance.isInitialized
    }
}

struct ObjCUnifiedAdNetworkInitializer: UnifiedAdNetworkInitializer {
    let instance: AdNetworkInitializerObjC.Type

    func initialize(config: Any?, completion: @escaping (Bool, Error?) -> Void) {
        let initializer = instance.createInstance() as! AdNetworkInitializerObjC
        initializer.initialize?(config: config as? ObjCBidderConfigProtocol, completion: completion)
    }

    var isInitialized: Bool {
        return instance.isInitialized
    }
}
