import Foundation
import CloudXCore

struct DemoAppLogEntry {
    let message: String
    let timestamp: Date
    let formattedTimestamp: String
    
    init(message: String) {
        self.message = message
        self.timestamp = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        self.formattedTimestamp = formatter.string(from: timestamp)
    }
}

class DemoAppLogger {
    static let sharedInstance = DemoAppLogger()
    
    private var logs: [DemoAppLogEntry] = []
    private let logQueue = DispatchQueue(label: "com.cloudx.demo.logger", qos: .utility)
    
    private init() {}
    
    func logMessage(_ message: String?) {
        guard let message = message else { return }
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let entry = DemoAppLogEntry(message: message)
            self.logs.append(entry)
            
            // Also log to console for Xcode debugging
            print("📱 [DemoApp] \(message)")
            
            // Keep only the last 500 logs to prevent memory issues
            if self.logs.count > 500 {
                self.logs.removeFirst()
            }
        }
    }
    
    func logAdEvent(_ eventName: String?, ad: CLXAd?) {
        guard let eventName = eventName else { return }
        
        let adDetails = DemoAppLogger.formatAdDetails(ad)
        let fullMessage = "\(eventName)\(adDetails)"
        logMessage(fullMessage)
    }
    
    func clearLogs() {
        logQueue.async { [weak self] in
            self?.logs.removeAll()
        }
    }
    
    func getAllLogs() -> [DemoAppLogEntry] {
        return logQueue.sync {
            return Array(logs)
        }
    }
    
    var logCount: Int {
        return logQueue.sync {
            return logs.count
        }
    }
    
    static func formatAdDetails(_ ad: CLXAd?) -> String {
        guard let ad = ad else {
            return " - Ad: (null)"
        }
        
        var details = " - Ad Details:"
        
        // Ad Unit Name
        if let placementName = ad.placementName {
            details += "\n  📍 Ad Unit: \(placementName)"
        } else {
            details += "\n  📍 Ad Unit: (null)"
        }
        
        // Ad Unit ID
        if let placementId = ad.placementId {
            details += "\n  🆔 Ad Unit ID: \(placementId)"
        } else {
            details += "\n  🆔 Ad Unit ID: (null)"
        }
        
        // Bidder/Network
        if let bidder = ad.bidder {
            details += "\n  🏢 Bidder: \(bidder)"
        } else {
            details += "\n  🏢 Bidder: (null)"
        }
        
        // External Placement ID
        if let externalPlacementId = ad.externalPlacementId {
            details += "\n  🔗 External ID: \(externalPlacementId)"
        } else {
            details += "\n  🔗 External ID: (null)"
        }
        
        // Revenue
        if let revenue = ad.revenue {
            details += String(format: "\n  💰 Revenue: $%.6f", revenue.doubleValue)
        } else {
            details += "\n  💰 Revenue: (null)"
        }
        
        return details
    }
}