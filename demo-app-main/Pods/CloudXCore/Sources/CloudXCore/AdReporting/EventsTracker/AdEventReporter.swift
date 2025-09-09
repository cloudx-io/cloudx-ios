//
//  AdEventReporter.swift
//  
//
//  Created by bkorda on 04.03.2024.
//

import UIKit

protocol AdEventReporting {
    func impression(bidID: String)
    func win(bidID: String)
    func showBannerNUrlAction(price: Double, nUrl: String?)
    func rillTracking(urlString: String, encodedString: String)
}

final class LiveAdEventReporter: AdEventReporting {
    
    private let reportNetworkService: AdReportingNetworkService
    
    init(endpoint: String) {
        var endpointString = endpoint.count > 0 ? endpoint : "https://ads.cloudx.io/event?a=test"
        let endpoint = URL(string: endpointString)!
        reportNetworkService = AdReportingNetworkService(baseURL: endpoint, urlSession: URLSession.cloudxSession(with: "io.cloudx.event.reporter"))
    }
    
    func impression(bidID: String) {
        Task {
            try await self.reportNetworkService.trackImpression(bidID: bidID)
        }
    }
    
    func win(bidID: String) {
        Task {
            try await self.reportNetworkService.trackWin(bidID: bidID)
        }
    }
    
    func showBannerNUrlAction(price: Double, nUrl: String?) {
        Task {
            try await self.reportNetworkService.trackNUrl(price: price, nUrl: nUrl)
        }
    }
    
    func rillTracking(urlString: String, encodedString: String) {
        Task {
            try await self.reportNetworkService.rillTracking(urlString: urlString, encodedString: encodedString)
        }
    }
    
}


