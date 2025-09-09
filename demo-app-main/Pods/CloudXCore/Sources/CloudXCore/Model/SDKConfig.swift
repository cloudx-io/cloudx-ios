//
//  SDKConfig.swift
//  CloudXCore
//
//  Created by bkorda on 04.02.2024.
//

import Foundation

/// Configuration for the ad network SDK such as app id, ad unit id, etc.
public protocol BidderConfig {
    /// Bid network SDK's specific data required for its initializing.
    var initData: [String: String] { get }
    /// Bid network's name; required for resolving active bid network adapter implementations on CloudX SDK side.
    var networkName: String { get }
}

struct SDKConfig {
    
    struct Request: RequestParameters, Encodable {
        var urlParams: [String: String] = [:]
        
        let bundle: String
        let os: String
        let osVersion: String
        let model: String
        let vendor: String
        let ifa: String
        let ifv: String
        let sdkVersion: String
        let dnt: Bool
        let imp: [Imp]
        let id: String
        
        struct Imp: Encodable {
            let id: String
            let banner: Banner?
            
            struct Banner: Encodable {
                let format: [Format]
                
                struct Format: Encodable {
                    let w: Int
                    let h: Int
                }
            }
        }
    }
    
    struct Response: Decodable {
        let metricsEndpointURL: String?
        let sessionID: String?
        let preCacheSize: Int
        let auctionEndpointURL: EndpointQuantumValue
        let cdpEndpointURL: EndpointObject?
        let eventTrackingURL: String?
        let placements: [Placement]
        let bidders: [Bidder]
        let seatbid: [SeatBid]?
        let cur: String?
        let id: String?
        let bidid: String?
        let impressionTrackerURL: String?
        let organizationID: String?
        let accountID: String?
        let tracking: [String]?
    
        struct SeatBid: Decodable {
            let bid: [Bid]
            let seat: String
        }
        
        struct Bid: Decodable {
            let id: String
            let impid: String
            let price: Double
            let adm: String
            let adid: String
            let adomain: [String]
            let crid: String
            let w: Int
            let h: Int
            let ext: BidExt?
            
            struct BidExt: Decodable {
                let origbidcpm: Double?
                let origbidcur: String?
                let cloudx: CloudXExt?
                
                struct CloudXExt: Decodable {
                    let meta: Meta?
                    let rank: Int?
                    
                    struct Meta: Decodable {
                        let adaptercode: String
                    }
                }
            }
        }
        
        struct EndpointQuantumValue: Decodable {

            public var endpointObject: EndpointObject?
            public var endpointString: String?

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let endpointString = try? container.decode(String.self) {
                    self.endpointString = endpointString
                    return
                }
                if let endpointObject = try? container.decode(EndpointObject.self) {
                    self.endpointObject = endpointObject
                    return
                }
                throw QuantumError.missingValue
            }
            
            enum QuantumError: Error {
                 case missingValue
            }

            func value() -> Any? {
                if let string = endpointString {
                    return string
                }
                if let object = endpointObject {
                    return object
                }
                return nil
            }
        }
        
        struct EndpointObject: Decodable {
            let test: [EndpointValue]?
            let defaultKey: String
            
            enum CodingKeys: String, CodingKey {
                case defaultKey = "default"
                case test
            }
        }
        
        struct EndpointValue: Decodable {
            let name: String?
            let value: String
            let ratio: Double
        }
        
        struct Placement: Decodable {
            enum AdType: String, Decodable {
                case banner = "BANNER"
                case mrec = "MREC"
                case interstitial = "INTERSTITIAL"
                case rewarded = "REWARDED"
                case unknown = "UNKNOWN"
                
                var ilrdDescription: String {
                    switch self {
                    case .banner:
                        return "Banner"
                    case .rewarded:
                        return "Rewarded video"
                    case .interstitial:
                        return "Interstitial"
                    case .mrec:
                        return "MREC"
                    default:
                        return ""
                    }
                }
                
                public init(from decoder: Decoder) throws {
                    self = try AdType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
                }
            }
            
            let id: String
            let name: String
            let bidResponseTimeoutMs: Int64
            let adLoadTimeoutMs: Int64
            let bannerRefreshRateMs: Int64?
            let type: AdType
            let hasCloseButton: Bool?
            let firstImpressionPlacementSuffix: String?
            let firstImpressionLoopIndexStart: Int?
            let firstImpressionLoopIndexEnd: Int?
            let nativeTemplate: CloudXNativeTemplate?
            let dealId: String?
            let line_items: [LineItem]?
            
            struct LineItem: Decodable {
                
                    let suffix: String?
                    let targeting: QuantumValue?
                    
                struct Targeting: Codable {
                    let strategy: String
                    let conditionsAnd: Bool
                    let conditions: [Condition]
                    
                    struct Condition: Codable {
                        let whitelist: [[String: QuantumValue]?]?
                        let blacklist: [[String: QuantumValue]?]?
                        let and: Bool
                        
                        struct QuantumValue: Codable {
                            
                            public var string: String?
                            public var integer: Int?
                            
                            init(from decoder: Decoder) throws {
                                let container = try decoder.singleValueContainer()
                                if let int = try? container.decode(Int.self) {
                                    self.integer = int
                                    return
                                }
                                if let string = try? container.decode(String.self) {
                                    self.string = string
                                    return
                                }
                                throw QuantumError.missingValue
                            }
                            
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.singleValueContainer()
                                try container.encode(string)
                                try container.encode(integer)
                            }
                            
                            enum QuantumError: Error {
                                case missingValue
                            }
                            
                            func value() -> Any? {
                                if let s = string {
                                    return s
                                }
                                if let i = integer {
                                    return i
                                }
                                return nil
                            }
                        }
                        
                    }
                }
                
                struct QuantumValue: Codable {

                    public var targetingStrategy: TargetingStrategy?
                    public var targeting: Targeting?

                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if let targeting = try? container.decode(Targeting.self) {
                            self.targeting = targeting
                            return
                        }
                        if let targetingStrategy = try? container.decode(TargetingStrategy.self) {
                            self.targetingStrategy = targetingStrategy
                            return
                        }
                        throw QuantumError.missingValue
                    }

                    func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        try container.encode(targetingStrategy)
                        try container.encode(targeting)
                    }

                    enum QuantumError: Error {
                         case missingValue
                    }

                    func value() -> Any? {
                        if let s = targeting {
                            return s
                        }
                        if let i = targetingStrategy {
                            return i
                        }
                        return nil
                    }
                }
                
                struct TargetingStrategy: Codable {
                    let strategy: String
                }
            }
        }
        
        struct Bidder: Decodable, BidderConfig {
            // Bid network SDK's specific data required for its initializing.
            let initData: [String: String]
            // Bid network's name; required for resolving active bid network adapter implementations on CloudX SDK side.
            let networkName: String
            
            var networkNameMapped: KnownAdapterName {
                KnownAdapterName(rawValue: networkName) ?? .demo
            }
        }
    }
    
    enum KnownAdapterName: String, CaseIterable, Hashable {
        //    case mockery = "Mockery"
        case demo = "testbidder"
        case adManager = "googleAdManager"
        case meta = "meta"
        case mintegral = "mintegral"
        case cloudx = "cloudx"
        
        var className: String {
            switch self {
            case .demo:
                return "TestVastNetwork"
            case .adManager:
                return "AdManager"
            case .meta:
                return "Meta"
            case .mintegral:
                return "Mintegral"
            case .cloudx:
                return "DSP"
            }
        }
        
        init?(rawValue: String) {
            switch rawValue {
            case "testbidder":
                self = .demo
            case "googleAdManager":
                self = .adManager
            case "meta":
                self = .meta
            case "mintegral":
                self = .mintegral
            case "cloudx":
                self = .cloudx
            default:
                return nil
            }
        }
    }
    
}

// Objective-C compatible protocol
@objc public protocol ObjCBidderConfigProtocol {
    var initData: NSDictionary { get }
    var networkName: NSString { get }
}
