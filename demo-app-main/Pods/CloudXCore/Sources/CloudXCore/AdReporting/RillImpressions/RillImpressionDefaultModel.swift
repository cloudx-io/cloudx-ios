//
//  RillImpressionDefaultModel.swift
//  CloudXCore
//
//  Created by Xenoss on 15.05.2025.
//

struct RillImpressionDefaultModel {
    
    var bidder: String // ✅ cloudxdsp, cloudxsecond, testnetwork
    var width: Int = 320   // ✅ 320
    var height: Int = 50   // ✅ 50
    
    var dealId: String? // ✅
    var creativeId: String = "creativeId_absent_from_bid" // ❓placementId? adm? -- if bid has it, add it
    var cpmMicros: Double? // ✅ price // BidResponse
    var responseTimeMillis: Int? // ✅  BidResponse time in millis
    
    var releaseVersion: String = "1.0.0" // ✅ SDK version
    var auctionId: String? // ❓BidResponse `id`? // smth unique for each auction (may be some uuid in SSP response, or generate new random uuid)
    var accountId: String // ❓ -- add accountId into sdk config (later will come from provisioning as well)
    var organizationId: String // ❓ -- add organizationId into sdk config (later will come from provisioning as well)
    var applicationId: String // ✅
    var placementId: String // ✅
    var deviceName: String = SystemInformation.shared.model //  ✅
    var deviceType: String = SystemInformation.shared.deviceType.stringValue //  ✅
    var osName: String = SystemInformation.shared.os // ✅
    var osVersion: String = SystemInformation.shared.systemVersion // ✅
    var sessionId: String // ✅ from config --should be generated each time we init sdk (some random UUID)
    var ifa: String // ✅
    var loopIndex: Int // ✅
    var testGroupName: String
    
    func createParamString() -> String {
        var resultString = ""
        
        resultString += "\(bidder)".semicolon()
        resultString += "\(width)".semicolon()
        resultString += "\(height)".semicolon()
        resultString += "\(dealId ?? "dealId_absent_from_bid")".semicolon()
        resultString += "\(creativeId)".semicolon()
        resultString += "\(cpmMicros ?? 0)".semicolon()
        resultString += "\(responseTimeMillis ?? 0)".semicolon()
        resultString += "\(releaseVersion)".semicolon()
        resultString += "\(auctionId ?? "")".semicolon()
        resultString += "\(accountId)".semicolon()
        resultString += "\(organizationId)".semicolon()
        resultString += "\(applicationId)".semicolon()
        resultString += "\(placementId)".semicolon()
        resultString += "\(deviceName)".semicolon()
        resultString += "\(deviceType)".semicolon()
        resultString += "\(osName)".semicolon()
        resultString += "\(osVersion)".semicolon()
        resultString += "\(sessionId)".semicolon()
        resultString += "\(ifa)".semicolon()
        resultString += "\(loopIndex)".semicolon()
        resultString += "\(testGroupName)".semicolon()
                
        return resultString
    }
}
