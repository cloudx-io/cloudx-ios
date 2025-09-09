//
//  RillImpressionModel.swift.swift
//  CloudXCore
//
//  Created by Xenoss on 22.05.2025.
//

struct RillImpressionModel {
    let lastBidResponse: BidAdSourceResponse
    let impModel: ConfigImpressionModel
    let adapterName: String
    let loadBannerTimesCount: Int
    let placementID: String
}

enum ConfigProperty: String {
    case metricsEndpointURL = "config.metricsEndpointURL"
    case sessionID = "config.sessionID"
    case preCacheSize = "config.preCacheSize"
    case eventTrackingURL = "config.eventTrackingURL"
    case cur = "config.cur"
    case id = "config.id"
    case bidid = "config.bidid"
    case impressionTrackerURL = "config.impressionTrackerURL"
    case organizationID = "config.organizationID"
    case accountID = "config.accountID"
}

enum BidProperty: String {
    case id = "bid.id"
    case adm = "bid.adm"
    case adid = "bid.adid"
    case impid = "bid.impid"
    case bundle = "bid.bundle"
    case burl = "bid.burl"
    case adomain = "bid.adomain"
    case price = "bid.price"
    case abTestId = "bid.abTestId"
    case abTestGroup = "bid.abTestGroup"
    case nurl = "bid.nurl"
    case iurl = "bid.iurl"
    case cat = "bid.cat"
    case cid = "bid.cid"
    case crid = "bid.crid"
    case dealid = "bid.dealid"
    case w = "bid.w"
    case h = "bid.h"

    // Nested Ext properties
    case ext_origbidcpm = "bid.ext.origbidcpm"
    case ext_origbidcur = "bid.ext.origbidcur"

    // Nested Ext.CloudX properties
    case ext_cloudx_rank = "bid.ext.cloudx.rank"
    case ext_cloudx_adapterExtras = "bid.ext.cloudx.adaptextras"

    // Nested Ext.CloudX.Meta property
    case ext_cloudx_meta_adaptercode = "bid.ext.cloudx.meta.adaptercode"

    // Nested Ext.SKAd properties
    case ext_skadn_version = "bid.ext.skadn.version"
    case ext_skadn_network = "bid.ext.skadn.network"
    case ext_skadn_sourceidentifier = "bid.ext.skadn.sourceidentifier"
    case ext_skadn_campaign = "bid.ext.skadn.campaign"
    case ext_skadn_itunesitem = "bid.ext.skadn.itunesitem"
    case ext_skadn_productpageid = "bid.ext.skadn.productpageid"
    case ext_skadn_nonce = "bid.ext.skadn.nonce"
    case ext_skadn_sourceapp = "bid.ext.skadn.sourceapp"
    case ext_skadn_timestamp = "bid.ext.skadn.timestamp"
    case ext_skadn_signature = "bid.ext.skadn.signature"

    // Nested Ext.SKAd.Fidelity properties
    case ext_skadn_fidelities_fidelity = "bid.ext.skadn.fidelities.fidelity"
    case ext_skadn_fidelities_nonce = "bid.ext.skadn.fidelities.nonce"
    case ext_skadn_fidelities_signature = "bid.ext.skadn.fidelities.signature"
    case ext_skadn_fidelities_timestamp = "bid.ext.skadn.fidelities.timestamp"
}

enum BidRequestProperty: String, CaseIterable {
    // Root level
    case id = "bidRequest.id"
    
    // app
    case app_id = "bidRequest.app.id"
    case app_ver = "bidRequest.app.ver"
    case app_bundle = "bidRequest.app.bundle"

    // ext
    case ext_adapter_extras_mintegral_buyer_id = "bidRequest.ext.adapterExtras.mintegral.buyerId"
    case ext_prebid_adservertargeting_key = "bidRequest.ext.prebid.adservertargeting.key"
    case ext_prebid_adservertargeting_value = "bidRequest.ext.prebid.adservertargeting.value"
    case ext_prebid_adservertargeting_source = "bidRequest.ext.prebid.adservertargeting.source"

    // regs
    case regs_coppa = "bidRequest.regs.coppa"
    case regs_ext_ccpa_do_not_sell = "bidRequest.regs.ext.ccpa_do_not_sell"
    case regs_ext_gdpr_consent = "bidRequest.regs.ext.gdpr_consent"
    case regs_ext_iab_gdpr_tcfv2_gdpr_applies = "bidRequest.regs.ext.gdpr_tcfv2_gdpr_applies"

    // device
    case device_os = "bidRequest.device.os"
    case device_ifa = "bidRequest.device.ifa"
    case device_hwv = "bidRequest.device.hwv"
    case device_h = "bidRequest.device.h"
    case device_ppi = "bidRequest.device.ppi"
    case device_js = "bidRequest.device.js"
    case device_language = "bidRequest.device.language"
    case device_dnt = "bidRequest.device.dnt"
    case device_ua = "bidRequest.device.ua"
    case device_devicetype = "bidRequest.device.devicetype"
    case device_geo_utcoffset = "bidRequest.device.geo.utcoffset"
    case device_pxratio = "bidRequest.device.pxratio"
    case device_lmt = "bidRequest.device.lmt"
    case device_osv = "bidRequest.device.osv"
    case device_w = "bidRequest.device.w"
    case device_model = "bidRequest.device.model"
    case device_connectiontype = "bidRequest.device.connectiontype"
    case device_make = "bidRequest.device.make"

    // imp
    case imp_id = "bidRequest.imp.id"
    case imp_tagid = "bidRequest.imp.tagid"
    case imp_secure = "bidRequest.imp.secure"
    case imp_ext_prebid_storedimpression_id = "bidRequest.imp.ext.prebid.storedimpression.id"
    case imp_banner_format_w = "bidRequest.imp.banner.format.w"
    case imp_banner_format_h = "bidRequest.imp.banner.format.h"

    // user
    case user_ext_prebid_buyeruids_cloudx = "bidRequest.user.ext.prebid.buyeruids.cloudx"
}
