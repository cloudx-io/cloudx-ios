//
//  ConfigImpressionModel.swift
//  CloudXCore
//
//  Created by Xenoss on 16.05.2025.
//


struct ConfigImpressionModel {
    let sessionID: String
    let auctionID: String
    let impressionTrackerURL: String
    let organizationID: String
    let accountID: String
    let sdkConfig: SDKConfig.Response?
    let testGroupName: String
}
