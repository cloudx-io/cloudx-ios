//
//  AdReportingNetworkService.swift
//  
//
//  Created by bkorda on 07.03.2024.
//

import UIKit

final class AdReportingNetworkService: BaseNetworkService {
    
    private let logger = Logger(category: "AdReporting")
    let endpoint: String = ""
    func trackImpression(bidID: String) async throws {
        try await executeRequest(method: .get, endpoint: endpoint, urlParameters: ["b" : bidID, "t" : "imp"], requestBody: nil, headers: nil, maxRetries: 3, delay: 1)
        let url = self.baseURL.appending(parameters: ["b" : bidID, "t" : "imp"])
        logger.debug("track url: \(String(describing: url))")
//        _ = try await session.data(from: url!)
    }
    
    func trackWin(bidID: String) async throws {
        try await executeRequest(method: .get, endpoint: endpoint, urlParameters: ["t" : "win", "b" : bidID], requestBody: nil, headers: nil, maxRetries: 3, delay: 1)
        let url = self.baseURL.appending(parameters: ["b" : bidID, "t" : "win"])
        logger.debug("CloudX: track url: \(String(describing: url))")
//        _ = try await session.data(from: url!)
        
    }
    
    func rillTracking(urlString: String, encodedString: String) async throws {
        guard let url = URL(string: urlString) else {
            return logger.debug("CloudX: cant parse rillTracking to URL: \(urlString)")
        }
        let params = ["impression" : encodedString, "campaignId": "c1", "eventValue": "1", "eventName": "imp"]
        try await executeFullPathRequest(urlParameters: params, url: url, maxRetries: 3, delay: 1)
        logger.debug("CloudX: rillTracking: \(String(describing: url))")
    }
    
    func trackNUrl(price: Double, nUrl: String?) async throws {
        guard let nUrl = nUrl else {
            return logger.debug("CloudX: nUrl is empty")
        }
        
        let replaced = nUrl.replacingOccurrences(of: "${AUCTION_PRICE}", with: "\(price)")
        
        guard let url = URL(string: replaced) else {
            return logger.debug("CloudX: cant parse nUrl to URL: \(replaced)")
        }
        
        try await executeFullPathRequest(url: url, maxRetries: 3, delay: 1)
        logger.debug("CloudX: track Nurl: \(String(describing: url))")
    }
}
