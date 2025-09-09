//
//  CloudXMintegralBidTokenSource.swift
//
//
//  Created by bkorda on 29.07.2024.
//

import Foundation
import CloudXCore
import MTGSDKBidding

final class CloudXMintegralBidTokenSource: BidTokenSource {
    
    func getToken() async throws -> [String : String] {
        return ["buyer_id" : MTGBiddingSDK.buyerUID()]
    }
    
    static func createInstance() -> CloudXMintegralBidTokenSource {
        CloudXMintegralBidTokenSource()
    }
    
}
