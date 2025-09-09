//
//  SDKInitNetworkService.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import Foundation
import UIKit

final class SDKInitNetworkService: BaseNetworkService {
    
    private let endpoint = ""
    
    private enum APIRequestKey {
        static let appKey = "appKey"
        static let lat = "lat"
        static let ifa = "ifa"
    }
    
    override var headers: HTTPHeaders {
        [
            "Content-Type": "application/json"
        ]
    }
    
    private var backOffStrategy = ExponentialBackoffStrategy(initialDelay: 1, maxDelay: 60, maxAttempts: 5)
    let logger = Logger(category: "SDKInitNetworkService")
    
    func initSDK(appKey: String) async throws -> SDKConfig.Response {
        while let delay = try? backOffStrategy.nextDelay() {
            logger.info("Attempt to init SDK with delay: \(delay)")
            let request = self.createRequest()
            
            var headers = self.headers
            headers["Authorization"] = "Bearer \(appKey)"
            do {
                sleep(UInt32(delay))
                return try await executeRequest(endpoint: endpoint, urlParameters: nil, requestBody: request.json, headers: headers, maxRetries: 1, delay: 0)
            } catch {
                logger.error("Attempt failed to init SDK with error: \(error)")
            }
        }
        
        backOffStrategy.reset()
        throw CloudXError.failToInitSDK
    }
    
    private func createRequest() -> SDKConfig.Request {
        // Use IDFV as rid for rollout
        let idfa: String = SystemInformation.shared.idfa ?? "00000-00000-00000-000000"
        let idfv: String = SystemInformation.shared.idfv ?? "00000-00000-00000-000000"
        return SDKConfig.Request(
            bundle: SystemInformation.shared.appBundleIdentifier,
            os: "iOS",
            osVersion: SystemInformation.shared.osVersion,
            model: UIDevice.deviceIdentifier,
            vendor: "Apple",
            ifa: idfa,
            ifv: idfv,
            sdkVersion: SystemInformation.shared.sdkVersion,
            dnt: SystemInformation.shared.dnt,
            imp: [],
            id: UUID().uuidString
        )
    }
}
