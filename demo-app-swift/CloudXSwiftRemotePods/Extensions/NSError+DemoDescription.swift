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
        if self.code == 204 || self.code == 301 { // CLXErrorCodeSDKDisabled or CLXErrorCodeAdsDisabled
            description += "\n⚠️ Kill Switch Active: SDK or ads have been remotely disabled via traffic control."
        }

        return description
    }

    /// Maps CloudX error codes to human-readable names
    private func cloudXErrorCodeName(_ code: Int) -> String? {
        switch code {
        // GENERAL ERRORS (0)
        case 0: return "Internal Error"

        // NETWORK ERRORS (100-199)
        case 100: return "Network Error"
        case 101: return "Network Timeout"
        case 102: return "Server Error"
        case 103: return "Client Error"
        case 104: return "Too Many Requests"
        case 105: return "Invalid Response"
        case 106: return "No Connection"

        // INITIALIZATION ERRORS (200-299)
        case 200: return "Not Initialized"
        case 201: return "No Adapters Found"
        case 202: return "No Networks Configured"
        case 203: return "Invalid App Key"
        case 204: return "SDK Disabled (Kill Switch)"

        // AD REQUEST/LOADING ERRORS (300-399)
        case 300: return "Invalid Ad Unit"
        case 301: return "Ads Disabled (Kill Switch)"
        case 302: return "No Fill"
        case 304: return "Load Failed"

        // AD DISPLAY/SHOW ERRORS (400-499)
        case 400: return "Ad Not Ready"
        case 401: return "Ad Already Showing"

        // CONFIGURATION/SETUP ERRORS (500-599)
        case 500: return "Invalid Native View"

        default: return nil
        }
    }
}


