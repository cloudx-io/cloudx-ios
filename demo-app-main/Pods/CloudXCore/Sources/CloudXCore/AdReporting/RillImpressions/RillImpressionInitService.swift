//
//  RillImpressionInitService.swift
//  CloudXCore
//
//  Created by Xenoss on 22.05.2025.
//

import Foundation

class RillImpressionInitService {
    
    static func createDataString(with rillImpressionModel: RillImpressionModel) -> String {
        var resultString = ""
        
        guard let sdkConfig = rillImpressionModel.impModel.sdkConfig, let trackings = sdkConfig.tracking else { return createDefaultDataString(with: rillImpressionModel) }
        
        for tracking in trackings {
            if !sdkConfigSetup(sdkConfig, tracking).isEmpty {
                resultString += sdkConfigSetup(sdkConfig, tracking)
            }
            if !bidConfigSetup(rillImpressionModel.lastBidResponse.bid, tracking).isEmpty {
                resultString += bidConfigSetup(rillImpressionModel.lastBidResponse.bid, tracking)
            }
            if !bidRequestSetup(rillImpressionModel.lastBidResponse.bidRequest, tracking).isEmpty {
                resultString += bidRequestSetup(rillImpressionModel.lastBidResponse.bidRequest, tracking)
            }
            if !generalInfoSetup(rillImpressionModel, tracking).isEmpty {
                resultString += generalInfoSetup(rillImpressionModel, tracking)
            }
        }
        
        return resultString
    }
    
    private static func generalInfoSetup(_ rillImpressionModel: RillImpressionModel,_ tracking: String) -> String {
        var resultString = ""
        if tracking == "config.testGroupName" {
            resultString += rillImpressionModel.impModel.testGroupName.semicolon()
        }
        if tracking == "sdk.responseTimeMillis" {
            resultString += "\(Int(rillImpressionModel.lastBidResponse.latency))".semicolon()
        }
        if tracking == "sdk.releaseVersion" {
            resultString += "1.0.0".semicolon()
        }
        if tracking == "sdk.sessionId" {
            let result = rillImpressionModel.impModel.sessionID + UUID().uuidString
            resultString += result.semicolon()
        }
        if tracking == "bidRequest.loopIndex" {
            resultString += "\(rillImpressionModel.loadBannerTimesCount)".semicolon()
        }
        if tracking == "bid.creativeId" {
            resultString += "".semicolon()
        }
        if tracking == "config.placements[id=${bidRequest.imp.tagid}].name" {
            rillImpressionModel.impModel.sdkConfig?.placements.forEach { (placement) in
                if placement.id == rillImpressionModel.lastBidResponse.bidRequest.imp[0].tagid {
                    resultString += placement.name.semicolon()
                }
            }
        }
        if tracking == "sdk.deviceType" {
            resultString += SystemInformation.shared.deviceType.stringValue.semicolon()
        }
        return resultString
    }
    
    private static func sdkConfigSetup(_ sdkConfig: SDKConfig.Response,_ tracking: String) -> String {
        var resultString = ""
        let config = ConfigProperty(rawValue: tracking)
        switch config {
        case .metricsEndpointURL:
            resultString += sdkConfig.metricsEndpointURL ?? "".semicolon()
        case .sessionID:
            resultString += sdkConfig.sessionID ?? "".semicolon()
        case .preCacheSize:
            let stringValue = "\(sdkConfig.preCacheSize)".semicolon()
            resultString += stringValue
        case .eventTrackingURL:
            resultString += sdkConfig.eventTrackingURL ?? "".semicolon()
        case .cur:
            let stringValue = sdkConfig.cur ?? ""
            resultString += stringValue.semicolon()
        case .id:
            let stringValue = sdkConfig.id ?? ""
            resultString += stringValue.semicolon()
        case .bidid:
            let stringValue = sdkConfig.bidid ?? ""
            resultString += stringValue.semicolon()
        case .impressionTrackerURL:
            let stringValue = sdkConfig.impressionTrackerURL ?? ""
            resultString += stringValue.semicolon()
        case .organizationID:
            let stringValue = sdkConfig.organizationID ?? ""
            resultString += stringValue.semicolon()
        case .accountID:
            let stringValue = sdkConfig.accountID ?? ""
            resultString += stringValue.semicolon()
        case .none:
            _ = 1
        }
        return resultString
    }
    
    private static func bidConfigSetup(_ bid: BiddingConfig.Response.Bid,_ tracking: String) -> String {
        var resultString = ""
        let config = BidProperty(rawValue: tracking)
        switch config {
        case .id:
            let stringValue = bid.id ?? ""
            resultString += stringValue.semicolon()
        case .adm:
            let stringValue = bid.adm ?? ""
            resultString += stringValue.semicolon()
        case .adid:
            let stringValue = bid.adid ?? ""
            resultString += stringValue.semicolon()
        case .impid:
            let stringValue = bid.impid ?? ""
            resultString += stringValue.semicolon()
        case .bundle:
            let stringValue = bid.bundle ?? ""
            resultString += stringValue.semicolon()
        case .burl:
            let stringValue = bid.burl ?? ""
            resultString += stringValue.semicolon()
        case .adomain:
            let stringValue = bid.adomain ?? []
            resultString += stringValue.joined(separator: ",").semicolon()
        case .price:
            resultString += "\(bid.price)".semicolon()
        case .abTestId:
            let stringValue = bid.abTestId ?? 0
            resultString += "\(stringValue)".semicolon()
        case .abTestGroup:
            let stringValue = bid.abTestGroup ?? ""
            resultString += stringValue.semicolon()
        case .nurl:
            let stringValue = bid.nurl ?? ""
            resultString += stringValue.semicolon()
        case .iurl:
            let stringValue = bid.iurl ?? ""
            resultString += stringValue.semicolon()
        case .cat:
            let stringValue = bid.cat ?? []
            resultString += stringValue.joined(separator: ",").semicolon()
        case .cid:
            let stringValue = bid.cid ?? ""
            resultString += stringValue.semicolon()
        case .crid:
            let stringValue = bid.crid ?? ""
            resultString += stringValue.semicolon()
        case .dealid:
            let stringValue = bid.dealid ?? "dealId_absent_from_bid"
            resultString += stringValue.semicolon()
        case .w:
            let stringValue = bid.w ?? 0
            resultString += "\(stringValue)".semicolon()
        case .h:
            let stringValue = bid.h ?? 0
            resultString += "\(stringValue)".semicolon()
        // Nested Ext properties
        case .ext_origbidcpm:
            let stringValue = bid.ext?.origbidcpm ?? 0
            resultString += "\(stringValue)".semicolon()
        case .ext_origbidcur:
            let stringValue = bid.ext?.origbidcur ?? ""
            resultString += stringValue.semicolon()
        // Nested Ext.CloudX properties
        case .ext_cloudx_rank:
            resultString += "\(bid.ext?.cloudx?.rank ?? 0)".semicolon()
        case .ext_cloudx_adapterExtras:
            let stringValue = bid.ext?.cloudx?.adapterExtras ?? [:]
            resultString += stringValue.keys.joined(separator: ",").semicolon()
        // Nested Ext.CloudX.Meta property
        case .ext_cloudx_meta_adaptercode:
            let stringValue = bid.ext?.cloudx?.meta?.adaptercode ?? ""
            resultString += stringValue.semicolon()
        // Nested Ext.SKAd properties
        case .ext_skadn_version:
            let stringValue = bid.ext?.skadn?.version ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_network:
            let stringValue = bid.ext?.skadn?.network ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_sourceidentifier:
            let stringValue = bid.ext?.skadn?.sourceidentifier ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_campaign:
            let stringValue = bid.ext?.skadn?.campaign ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_itunesitem:
            let stringValue = bid.ext?.skadn?.itunesitem ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_productpageid:
            let stringValue = bid.ext?.skadn?.productpageid ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_nonce:
            let stringValue = bid.ext?.skadn?.nonce ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_sourceapp:
            let stringValue = bid.ext?.skadn?.sourceapp ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_timestamp:
            let stringValue = bid.ext?.skadn?.timestamp ?? ""
            resultString += stringValue.semicolon()
        case .ext_skadn_signature:
            let stringValue = bid.ext?.skadn?.signature ?? ""
            resultString += stringValue.semicolon()
        // Nested Ext.SKAd.Fidelity properties
        case .ext_skadn_fidelities_fidelity:
            var tempString = ""
            let fidelities = bid.ext?.skadn?.fidelities ?? []
            for fidelity in fidelities {
                tempString += "\(fidelity.fidelity)"
                tempString += ","
            }
            tempString.removeLast()
            resultString += tempString.semicolon()
        case .ext_skadn_fidelities_nonce:
            var tempString = ""
            let fidelities = bid.ext?.skadn?.fidelities ?? []
            for fidelity in fidelities {
                tempString += fidelity.nonce ?? ""
                tempString += ","
            }
            tempString.removeLast()
            resultString += tempString.semicolon()
        case .ext_skadn_fidelities_signature:
            var tempString = ""
            let fidelities = bid.ext?.skadn?.fidelities ?? []
            for fidelity in fidelities {
                tempString += fidelity.signature
                tempString += ","
            }
            tempString.removeLast()
            resultString += tempString.semicolon()
        case .ext_skadn_fidelities_timestamp:
            var tempString = ""
            let fidelities = bid.ext?.skadn?.fidelities ?? []
            for fidelity in fidelities {
                tempString += fidelity.timestamp
                tempString += ","
            }
            tempString.removeLast()
            resultString += tempString.semicolon()
        case .none:
            _ = 1
        }

        return resultString
    }
    
    private static func bidRequestSetup(_ bidRequest: BiddingConfig.Request,_ tracking: String) -> String {
        var resultString = ""
        let config = BidRequestProperty(rawValue: tracking)
        switch config {
        case .id:
        resultString += bidRequest.id.semicolon()
        // app
        case .app_id:
            resultString += bidRequest.app.id.semicolon()
        case .app_ver:
            resultString += bidRequest.app.ver.semicolon()
        case .app_bundle:
            resultString += bidRequest.app.bundle.semicolon()
        // ext
        case .ext_adapter_extras_mintegral_buyer_id:
            if let adapterExtras = bidRequest.ext?.adapterExtras, let dict = adapterExtras["mintegral"], let value = dict["buyer_id"] {
                resultString += value.semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .ext_prebid_adservertargeting_key:
            var stringArr: [String] = []
            if let adservertargeting = bidRequest.ext?.prebid?.adservertargeting {
                for targ in adservertargeting {
                    stringArr.append(targ.key)
                }
                resultString += stringArr.joined(separator: ",").semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .ext_prebid_adservertargeting_value:
            var stringArr: [String] = []
            if let adservertargeting = bidRequest.ext?.prebid?.adservertargeting {
                for targ in adservertargeting {
                    stringArr.append(targ.value)
                }
                resultString += stringArr.joined(separator: ",").semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .ext_prebid_adservertargeting_source:
            var stringArr: [String] = []
            if let adservertargeting = bidRequest.ext?.prebid?.adservertargeting {
                for targ in adservertargeting {
                    stringArr.append(targ.source)
                }
                resultString += stringArr.joined(separator: ",").semicolon()
            } else {
                resultString += "".semicolon()
            }
        // regs
        case .regs_coppa:
            if let stringValue = bidRequest.regs.coppa {
                resultString += "\(stringValue)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .regs_ext_ccpa_do_not_sell:
            if let stringValue = bidRequest.regs.ext?.ccpa {
                resultString += "\(stringValue)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .regs_ext_gdpr_consent:
            if let stringValue = bidRequest.regs.ext?.gdpr {
                resultString += "\(stringValue)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .regs_ext_iab_gdpr_tcfv2_gdpr_applies:
            if let stringValue = bidRequest.regs.ext?.iab {
                resultString += "\(stringValue)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        // device
        case .device_os:
            resultString += bidRequest.device.os.semicolon()
        case .device_ifa:
            resultString += bidRequest.device.ifa.semicolon()
        case .device_hwv:
            resultString += bidRequest.device.hwv.semicolon()
        case .device_h:
            resultString += "\(bidRequest.device.h)".semicolon()
        case .device_ppi:
            resultString += "\(bidRequest.device.ppi)".semicolon()
        case .device_js:
            resultString += "\(bidRequest.device.js)".semicolon()
        case .device_language:
            resultString += bidRequest.device.language.semicolon()
        case .device_dnt:
            resultString += "\(bidRequest.device.dnt)".semicolon()
        case .device_ua:
            resultString += bidRequest.device.ua.semicolon()
        case .device_devicetype:
            resultString += SystemInformation.shared.deviceType.stringValue.semicolon()
        case .device_geo_utcoffset:
            resultString += "\(bidRequest.device.geo.utcoffset)".semicolon()
        case .device_pxratio:
            resultString += "\(Int(bidRequest.device.pxratio))".semicolon()
        case .device_lmt:
            resultString += "\(bidRequest.device.lmt ?? 0)".semicolon()
        case .device_osv:
            resultString += bidRequest.device.osv.semicolon()
        case .device_w:
            resultString += "\(bidRequest.device.w)".semicolon()
        case .device_model:
            resultString += bidRequest.device.model.semicolon()
        case .device_connectiontype:
            resultString += "\(bidRequest.device.connectiontype)".semicolon()
        case .device_make:
            resultString += bidRequest.device.make.semicolon()
        // imp
        case .imp_id:
            if let value = bidRequest.imp.first {
                resultString += value.id.semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .imp_tagid:
            if let value = bidRequest.imp.first {
                resultString += value.tagid.semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .imp_secure:
            if let value = bidRequest.imp.first {
                resultString += "\(value.secure)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .imp_ext_prebid_storedimpression_id:
            if let value = bidRequest.imp.first {
                let stringValue = value.ext?.prebid.storedimpression.id ?? ""
                resultString += stringValue.semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .imp_banner_format_w:
            if let value = bidRequest.imp.first, let first = value.banner?.format.first {
                resultString += "\(first.w)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .imp_banner_format_h:
            if let value = bidRequest.imp.first, let first = value.banner?.format.first {
                resultString += "\(first.h)".semicolon()
            } else {
                resultString += "".semicolon()
            }
        // user
        case .user_ext_prebid_buyeruids_cloudx:
            if let dict = bidRequest.user?.ext?.prebid?.buyeruids, let value = dict["cloudx"] {
                resultString += value.semicolon()
            } else {
                resultString += "".semicolon()
            }
        case .none:
            _ = 1
        }
        return resultString
    }
    
    private static func createDefaultDataString(with rillImpressionModel: RillImpressionModel) -> String {
        let resultString = ""
        
        var bundle = ""
        if let bundleString = UserDefaults.standard.string(forKey: "bundle_config"), !bundleString.isEmpty {
            bundle = bundleString
        }
        
        var ifa = SystemInformation.shared.idfa ?? "ifa-ReportingTest-testMainWorkflow-XGcmO7"
        
        if let ifaString = UserDefaults.standard.string(forKey: "ifa_config"), !ifaString.isEmpty {
            ifa = ifaString
        }
        
        let lastBidResponse = rillImpressionModel.lastBidResponse
        let impModel = rillImpressionModel.impModel
        
        let rillModel = RillImpressionDefaultModel(bidder: rillImpressionModel.adapterName, dealId: lastBidResponse.dealId, cpmMicros: lastBidResponse.price, responseTimeMillis: Int(lastBidResponse.latency), auctionId: lastBidResponse.auctionId, accountId: impModel.accountID, organizationId: impModel.organizationID, applicationId: bundle, placementId: rillImpressionModel.placementID, sessionId: impModel.sessionID, ifa: ifa, loopIndex: rillImpressionModel.loadBannerTimesCount, testGroupName: impModel.testGroupName)
        
        let encodedString = rillModel.createParamString().data(using: .utf8)?.base64EncodedString()
        
        return encodedString ?? resultString
    }
}


