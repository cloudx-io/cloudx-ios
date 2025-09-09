//
//  BidNetworkService.swift
//  CloudXCore
//
//  Created by bkorda on 26.02.2024.
//

import Foundation
import WebKit

enum ConnectionType: Int {
    case unknown
    case ethernet
    case wifi
    case wwan
    case wwan2g
    case wwan3g
    case wwan4g
    
    init(reachabilityType: ReachabilityType) {
        switch reachabilityType {
        case .wifi:
            self = .wifi
        case .wwan:
            self = .wwan
        case .wwan2g:
            self = .wwan2g
        case .wwan3g:
            self = .wwan3g
        case .wwan4g:
            self = .wwan4g
        case .unknown:
            self = .unknown
        }
    }
    
    var stringValue: String {
        switch self {
        case .wifi:
            return "WIFI"
        case .wwan:
            return "CELLULAR_UNKNOWN"
        case .wwan2g:
            return "CELLULAR_2G"
        case .wwan3g:
            return "CELLULAR_3G"
        case .wwan4g:
            return "CELLULAR_4G"
        case .unknown:
            return "UNKNOWN"
        case .ethernet:
            return "ETHERNET"
        }
    }
    
    var intValue: Int {
        switch self {
        case .wifi:
            return 2
        case .wwan:
            return 3
        case .wwan2g:
            return 4
        case .wwan3g:
            return 5
        case .wwan4g:
            return 6
        case .unknown:
            return 0
        case .ethernet:
            return 1
        }
    }
}

struct SKAdRequestParameters {
    let versions: [String]
    let skadIDs: [String]
    let sourceApp: String
}

///All ad types supported by CloudX SDK. Needs to make Bid request.
enum AdType: String, Decodable {
    case banner = "BANNER"
    case mrec = "MREC"
    case interstitial = "INTERSTITIAL"
    case rewarded = "REWARD_VIDEO"
    case native = "NATIVE"
    case unknown = "UNKNOWN"
    
    ///Check if ad format is fullscreen or not.
    var isFullscreen: Bool {
        self == .rewarded || self == .interstitial
    }
    
    var bidResponseValue: String {
        return self.rawValue.lowercased()
    }
    
    public init(from decoder: Swift.Decoder) throws {
        self = try AdType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

///Allows you make bid request to CloudX bid auction.
protocol BidNetworkService {
    
    var isCDPEndpointEmpty: Bool { get set }
    
    /// Make BidRequest JSON
    /// - Parameters:
    ///   - adUnitID: ad unit id that you want request
    ///   - completion: request result.
    func createBidRequest(
        adUnitID: String,
        storedImpressionId: String,
        adType: AdType,
        dealID: String?,
        bidFloor: Float,
        publisherID: String,
        userID: String,
        adapterInfo: [CloudXCore.SDKConfig.KnownAdapterName : [String : String]],
        nativeAdRequirements: NativeAdRequirements?
    ) async throws -> BiddingConfig.Request
    
    /// Make request to CloudX bid auction and get bid response data in completion block.
    /// - Parameters:
    ///   - bidRequest: prepaired data in bidRequest
    ///   - completion: request result. Returns response `data` or `error`,
    func startAuction(with bidRequest: BiddingConfig.Request) async throws -> BiddingConfig.Response
    
    /// Make request to CDP and get enriched bid request data in completion block.
    /// - Parameters:
    ///   - bidRequest: prepaired data in bidRequest
    ///   - completion: request result. Returns response `data` or `error`,
    func startCDPFlow(with bidRequest: BiddingConfig.Request) async throws -> BiddingConfig.Request
    
}

@available(iOS 13.0, *)
final class BidNetworkServiceClass: BaseNetworkService, BidNetworkService {
    
    var isCDPEndpointEmpty: Bool
    
    private let endpoint = ""
    private let cdpEndpoint: String
    
    private enum APIRequestKey {
        
        static let apiKey = "apikey"
        static let accessKey = "acskey"
        
    }
    
    @MainActor
    private lazy var userAgent = WKWebView().value(forKey: "userAgent") as? String
    @Service(.singleton)
    private var locationService: GeoLocationService
    
    init(auctionEndpointUrl: String, cdpEndpointUrl: String) {
        self.cdpEndpoint = cdpEndpointUrl
        self.isCDPEndpointEmpty = cdpEndpointUrl.isEmpty
        super.init(baseURL: URL(string: auctionEndpointUrl)!, urlSession: URLSession.cloudxSession(with: "auction"))
    }
    
    required init(baseURL: URL, urlSession: URLSession) {
        fatalError("init(baseURL:urlSession:) has not been implemented")
    }
    
    func createBidRequest(
        adUnitID: String,
        storedImpressionId: String,
        adType: AdType,
        dealID: String?,
        bidFloor: Float,
        publisherID: String,
        userID: String,
        adapterInfo: [CloudXCore.SDKConfig.KnownAdapterName : [String : String]],
        nativeAdRequirements: NativeAdRequirements?
    ) async throws -> BiddingConfig.Request {
        let constants = SKAdNetworkService(systemVersion: SystemInformation.shared.systemVersion)
        let skadRequestParameters = constants.skadRequestParameters
        let bidRequest = await BiddingConfig.Request(
            adType: adType,
            adUnitID: adUnitID,
            storedImpressionId: storedImpressionId,
            dealID: dealID,
            bidFloor: bidFloor,
            displayManager: SystemInformation.shared.displayManager,
            displayManagerVer: SystemInformation.shared.sdkVersion,
            publisherID: publisherID,
            location: locationService.currentLocation,
            userAgent: userAgent,
            adapterInfo: adapterInfo,
            nativeAdRequirements: nativeAdRequirements,
            skadRequestParameters: skadRequestParameters)
        return bidRequest
    }
    
    func startCDPFlow(with bidRequest: BiddingConfig.Request) async throws -> BiddingConfig.Request {
        return try await self.executeRequest(
            method: .post, endpoint: cdpEndpoint, urlParameters: .none, requestBody: bidRequest.json,
            headers: [
                "Content-Type": "application/json", "User-Agent": userAgent ?? "",
            ], maxRetries: 0, delay: 0)
    }
    
    func startAuction(with bidRequest: BiddingConfig.Request) async throws -> BiddingConfig.Response {
        do {
            let response: BiddingConfig.Response = try await self.executeRequest(
                method: .post, endpoint: self.endpoint, urlParameters: .none, requestBody: bidRequest.json,
                headers: [
                    "Content-Type": "application/json", "User-Agent": userAgent ?? "",
                ], maxRetries: 0, delay: 0)
            return response
        } catch {
            print("[CloudX] Decoding error in startAuction: \(error)")
            throw error
        }
    }
}
