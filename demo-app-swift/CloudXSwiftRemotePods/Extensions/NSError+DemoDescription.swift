//
// NSError+DemoDescription.swift
// CloudXSwiftRemotePods
//
// Category for providing detailed, user-friendly error descriptions in the demo app
//

import Foundation

extension NSError {
    
    /// Returns a detailed, user-friendly error description suitable for display in alerts.
    /// Includes error code, domain, description, and relevant userInfo details.
    var detailedDemoDescription: String {
        var description = ""
        
        // Main error description
        description += "\(self.localizedDescription)\n\n"
        
        // Error details
        description += "Error Details:\n"
        description += "• Code: \(self.code)\n"
        
        // Add domain if not generic
        if self.domain != "NSCocoaErrorDomain" {
            description += "• Domain: \(self.domain)\n"
        }
        
        // Special handling for CloudX error codes
        if self.domain == "com.cloudx.sdk.error" {
            if let errorCodeName = self.cloudXErrorCodeName(self.code) {
                description += "• Error Type: \(errorCodeName)\n"
            }
        }
        
        // Add additional helpful info from userInfo
        
        // Failure reason if available
        if let failureReason = self.userInfo[NSLocalizedFailureReasonErrorKey] as? String, !failureReason.isEmpty {
            description += "• Reason: \(failureReason)\n"
        }
        
        // Recovery suggestion if available
        if let recoverySuggestion = self.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String, !recoverySuggestion.isEmpty {
            description += "\nSuggested Action:\n\(recoverySuggestion)"
        }
        
        // Add kill switch specific message
        if self.code == 105 || self.code == 308 { // CLXErrorCodeSDKDisabled or CLXErrorCodeAdsDisabled
            description += "\n⚠️ Kill Switch Active: SDK or ads have been remotely disabled via traffic control."
        }
        
        return description
    }
    
    /// Maps CloudX error codes to human-readable names
    private func cloudXErrorCodeName(_ code: Int) -> String? {
        switch code {
        // INITIALIZATION ERRORS (100-199)
        case 100: return "Not Initialized"
        case 101: return "Initialization In Progress"
        case 102: return "No Adapters Found"
        case 103: return "Initialization Timeout"
        case 104: return "Invalid App Key"
        case 105: return "SDK Disabled (Kill Switch)"
            
        // NETWORK ERRORS (200-299)
        case 200: return "Network Error"
        case 201: return "Network Timeout"
        case 202: return "Invalid Response"
        case 203: return "Server Error"
            
        // AD REQUEST/LOADING ERRORS (300-399)
        case 300: return "No Fill"
        case 301: return "Invalid Request"
        case 302: return "Invalid Placement"
        case 303: return "Load Timeout"
        case 304: return "Load Failed"
        case 305: return "Invalid Ad"
        case 306: return "Too Many Requests"
        case 307: return "Request Cancelled"
        case 308: return "Ads Disabled (Kill Switch)"
            
        // AD DISPLAY/SHOW ERRORS (400-499)
        case 400: return "Ad Not Ready"
        case 401: return "Ad Already Shown"
        case 402: return "Ad Expired"
        case 403: return "Invalid View Controller"
        case 404: return "Show Failed"
            
        // CONFIGURATION/SETUP ERRORS (500-599)
        case 500: return "Invalid Ad Unit"
        case 501: return "Permission Denied"
        case 502: return "Unsupported Ad Format"
        case 503: return "Invalid Banner View"
        case 504: return "Invalid Native View"
            
        default: return nil
        }
    }
}


