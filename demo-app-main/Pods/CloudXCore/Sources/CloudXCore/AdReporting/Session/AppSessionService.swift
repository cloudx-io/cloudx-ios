//
//  AppSessionService.swift
//
//
//  Created by bkorda on 05.03.2024.
//

import Foundation

protocol AppSessionService: AppSessionMetric {
    var sessionDuration: TimeInterval { get }
    var currentSession: AppSession { get }
}

final class AppSessionServiceImplementation: AppSessionService {
    
    private(set) var currentSession: AppSession
    
    var sessionDuration: TimeInterval {
        abs(currentSession.startDate.timeIntervalSinceNow)
    }
    
    func addSpend(placementID: String, spend: Double) {
        currentSession.addSpend(placementID: placementID, spend: spend)
    }
    
    func addClick(placementID: String) {
        currentSession.addClick(placementID: placementID)
    }
    
    func addImpression(placementID: String) {
        currentSession.addImpression(placementID: placementID)
    }
    
    func addClose(placementID: String, latency: Double) {
        currentSession.addClose(placementID: placementID, latency: latency)
    }
    
    func adFailedToLoad(placementID: String) {
        currentSession.adFailedToLoad(placementID: placementID)
    }
    
    func bidLoaded(placementID: String, latency: Double) {
        currentSession.bidLoaded(placementID: placementID, latency: latency)
    }
    
    func adLoaded(placementID: String, latency: Double) {
        currentSession.adLoaded(placementID: placementID, latency: latency)
    }
    
    init(sessionID: String, appKey: String, url: String) {
        
        if let url = URL(string: url) {
            self.currentSession = AppSession(sessionID: sessionID, url: url, appKey: appKey)
        } else {
            let url = URL(string: "https://ads.cloudx.io/metrics?a=test")
            self.currentSession = AppSession(sessionID: sessionID, url: url!, appKey: appKey)
        }
       
    }
}
