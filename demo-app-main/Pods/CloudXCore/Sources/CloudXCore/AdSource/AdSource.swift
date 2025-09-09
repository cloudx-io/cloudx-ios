//
//  AdSource.swift
//
//
//  Created by bkorda on 05.03.2024.
//

import UIKit

enum BidAdSourceError: Error {
    case noBid
}

protocol BidAdSourceProtocol {
    func requestBid(adUnitID: String,
                    storedImpressionId: String, successWin: Bool) async throws -> BidAdSourceResponse
}

struct BidAdSourceResponse {
    let price: Double
    let auctionId: String?
    let dealId: String?
    let latency: Double
    let nurl: String?
    let bidID: String
    let bid: BiddingConfig.Response.Bid
    let bidRequest: BiddingConfig.Request
    let networkName: String
    let createBidAd: @MainActor () -> Destroyable?
}

final class BidAdSource: BidAdSourceProtocol {
    typealias createBidAdFunc = (_ adId: String, _ bidId: String, _ adm: String, _ adapterExtras: [String: String], _ burl: String?, _ hasCloseButton: Bool, _ network: SDKConfig.KnownAdapterName) -> Destroyable?
    
    private let publisherID: String
    private let bidTokenSources: [SDKConfig.KnownAdapterName : BidTokenSource]
    @MainActor private var createBidAd: createBidAdFunc
    private let userID: String?
    private let placementID: String
    private let dealID: String?
    private let hasCloseButton: Bool
    private let adType: AdType
    private let logger = Logger(category: "BidAdSource")
    private var lastBidResponse: BiddingConfig.Response?
    private let nativeAdRequirements: NativeAdRequirements?
    
    private var latency: Double = 0
    
    @Service private var bidNetworkService: BidNetworkService
    @Service(.singleton) private var appSessionService: AppSessionService
    
    init(userID: String?,
         placementID: String,
         dealID: String?,
         hasCloseButton: Bool,
         publisherID: String,
         adType: AdType,
         bidTokenSources: [SDKConfig.KnownAdapterName : BidTokenSource],
         nativeAdRequirements: NativeAdRequirements?,
         createBidAd: @escaping createBidAdFunc) {
        
        self.createBidAd = createBidAd
        self.bidTokenSources = bidTokenSources
        self.adType = adType
        self.userID = userID
        self.publisherID = publisherID
        self.placementID = placementID
        self.dealID = dealID
        self.hasCloseButton = hasCloseButton
        
        self.nativeAdRequirements = nativeAdRequirements
    }
    
    func requestBid(adUnitID: String,
                    storedImpressionId: String, successWin: Bool) async throws -> BidAdSourceResponse {
        let networkNameTokenDict = await makeNetworkNameTokenDict(bidTokenSources: self.bidTokenSources)
        
        var bidRequest = try await self.bidNetworkService.createBidRequest(adUnitID: adUnitID, storedImpressionId: storedImpressionId, adType: self.adType, dealID: dealID, bidFloor: 0.01, publisherID: self.publisherID, userID: self.userID ?? "", adapterInfo: networkNameTokenDict, nativeAdRequirements: nativeAdRequirements)

        // CDP enrichment block
        if !self.bidNetworkService.isCDPEndpointEmpty {
            do {
                bidRequest = try await self.bidNetworkService.startCDPFlow(with: bidRequest)
                let data = bidRequest.ext?.prebid?.adservertargeting.first(
                    where: { object in object.source != "bidrequest" })
                CloudX.shared.logsData["cdpData"] = "\(data?.key ?? "") : \(data?.value ?? "")"
            } catch {
                print("[CloudX][BidSource] CDP flow threw error: \(error)")
                CloudX.shared.logsData["cdpDataError"] = "CDP error: \(error)"
            }
        }
        
        let bidRequestStart = Date()
        //if there is another bid in queue, use it
        guard !successWin, let bid = lastBidResponse?.getNextWinBid() else {
            //if there is no bid in queue or last bid was loaded successfully, request a new one
            lastBidResponse = try await self.bidNetworkService.startAuction(with: bidRequest)
            
            guard let newBid = lastBidResponse?.getNextWinBid() else {
                throw BidAdSourceError.noBid
            }
            var infoArr: [String] = []
            if let seatbids = lastBidResponse?.seatbid {
                for seatbid in seatbids {
                    seatbid.bid.forEach { bid in
                        let bidderString = "bidder: \(bid.ext?.adapter ?? ""), rank: \(bid.ext?.cloudx?.rank ?? 0)"
                        infoArr.append(bidderString)
                    }
                }
            }
            logger.debug(infoArr.joined(separator: ";"))
            CloudX.shared.logsData["bidderData"] = infoArr.joined(separator: " ||| ")
            
            let bidRequestFinished = Date()
            latency = bidRequestFinished.timeIntervalSince(bidRequestStart).milliseconds
            appSessionService.bidLoaded(placementID: placementID, latency: latency)
            return createBidAdSourceResponse(with: newBid, auctionID: lastBidResponse?.id, bidRequest: bidRequest)
        }
        
        return createBidAdSourceResponse(with: bid, auctionID: lastBidResponse?.id, bidRequest: bidRequest)
        
    }
    
    private func createBidAdSourceResponse(with bid: BiddingConfig.Response.Bid, auctionID: String?, bidRequest: BiddingConfig.Request) -> BidAdSourceResponse {
        let network = SDKConfig.KnownAdapterName(rawValue: bid.ext?.adapter ?? "TestVastNetwork") ?? .demo
        return BidAdSourceResponse(price: bid.price, auctionId: auctionID, dealId: bid.dealid, latency: latency, nurl: bid.nurl, bidID: bid.id!, bid: bid, bidRequest: bidRequest, networkName: network.rawValue) { @MainActor [weak self] in
            guard let `self` = self else { fatalError() }
            
            let bidAd = self.createBidAd(bid.adid ?? "", bid.id ?? "", bid.adm ?? "", bid.ext?.cloudx?.adapterExtras ?? [:], bid.burl, hasCloseButton, network)
            
            return bidAd
        }
    }
    
    // example
    //{
    //   "mintegral : {
    //      "buyer_id : "sdfsfdsfds"
    //   }
    // }
    private func makeNetworkNameTokenDict(bidTokenSources: [SDKConfig.KnownAdapterName : BidTokenSource]) async -> [SDKConfig.KnownAdapterName : [String : String]] {
        return await withTaskGroup(of: (SDKConfig.KnownAdapterName, [String : String]?).self) { group in
            for (adapterName, tokenSource) in bidTokenSources {
                group.addTask{
                    let token = try? await tokenSource.getToken()
                    return (adapterName, token)
                }
            }
            
            var networkNameTokenDict: [SDKConfig.KnownAdapterName : [String : String] ] = [:]
            for await (adapterName, token) in group {
                networkNameTokenDict[adapterName] = token
            }
            
            return networkNameTokenDict
        }
    }
}
