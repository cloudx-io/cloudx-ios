//
//  InitMetrics.swift
//
//
//  Created by bkorda on 22.04.2024.
//

import Foundation

struct InitMetrics {
    let appKey: String
    let startedAt: Date
    
    var endedAt: Date!
    var success: Bool = false
    var sessionId: String?
    
    init(appKey: String) {
        self.appKey = appKey
        self.startedAt = Date()
    }
    
    mutating func finish(sessionId: String?) {
        endedAt = Date()
        if let sessionId {
            success = true
        }
        self.sessionId = sessionId
    }
}
