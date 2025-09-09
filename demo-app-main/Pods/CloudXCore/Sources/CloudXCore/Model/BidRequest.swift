//
//  BidRequest.swift
//  CloudXCore
//
//  Created by bkorda on 27.02.2024.
//

import SwiftUI
import CoreLocation
import Foundation

struct BiddingConfig {
    
    struct Request: RequestParameters, Codable {
        init(
            adType: AdType,
            adUnitID: String,
            storedImpressionId: String,
            dealID: String?,
            bidFloor: Float?,
            displayManager: String,
            displayManagerVer: String,
            publisherID: String,
            location: CLLocation?,
            userAgent: String?,
            adapterInfo: [CloudXCore.SDKConfig.KnownAdapterName : [String : String]],
            nativeAdRequirements: NativeAdRequirements?,
            skadRequestParameters: SKAdRequestParameters?
        ) {
            let screenRect = UIScreen.main.bounds
            var screenWidth: Int = Int(screenRect.size.width)
            var screenHeight: Int = Int(screenRect.size.height)
            
            switch adType {
            case .mrec:
                screenWidth = 300
                screenHeight = 250
            case .banner:
                screenWidth = 320
                screenHeight = 50
            case .interstitial, .rewarded, .native:
                screenWidth = Int(screenRect.size.width)
                screenHeight = Int(screenRect.size.height)
            case .unknown:
                break
            }
            
            let format = Request
                .Impression
                .Banner
                .Format(w: screenWidth, h: screenHeight)
            
            let formatDouble = Request
                .Impression
                .Banner
                .Format(w: screenWidth, h: screenHeight)
            
            let banner = Request
                .Impression
                .Banner(
                    //w: screenWidth,
                    //h: screenHeight,
                    //pos: adType == .interstitial ? 7 : 0,
                    format: [format, formatDouble])
            
            let video = Request.Impression.Video(w: screenWidth, h: screenHeight)
            
            let id = Impression.Ext.Id.init(id: storedImpressionId)
            
            var targetingDict: [BiddingConfig.Request.Impression.Ext.AdserverTargeting] = []
            
            if let userDict = UserDefaults.standard.dictionary(forKey: "userKeyValue") as? [String: String] {
                for key in userDict.keys {
                    targetingDict.append(BiddingConfig.Request.Impression.Ext.AdserverTargeting(key: key, source: "bidrequest", value: userDict[key] ?? ""))
                }
            }
            
            let storedImpression = Impression.Ext.StoredImpression.init(adservertargeting: targetingDict, storedimpression: id)
            
            var impExt = Request.Impression.Ext(prebid: storedImpression)
//            var data: Data?
//            
//            if let userBidder = UserDefaults.standard.string(forKey: "userBidder"), let userBidderKey = UserDefaults.standard.string(forKey: "userBidderKey"), let userBidderValue = UserDefaults.standard.string(forKey: "userBidderValue") {
//                let ext = """
//                {
//                    "prebid": {
//                        "storedimpression": \(storedImpressionId)
//                    },
//                    "\(userBidder)": {
//                        "adservertargeting": [
//                            {
//                               "key": "\(userBidderKey)",
//                                "source": "bidrequest",
//                                 "value": "\(userBidderValue)"
//                             }
//                        ]
//                    }
//                }
//                """
//                
//               data = Data(ext.utf8)
//            }
            
            if let skadParams = skadRequestParameters {
                let skadNList = Request.Impression.Ext.SKadN.SkadNList(addl: skadParams.skadIDs)
                let skadn = Request.Impression.Ext.SKadN(sourceapp: skadParams.sourceApp, versions: skadParams.versions, skadnetlist: skadNList)
                //impExt.skadn = skadn
            }
            
            var pmp: Request.Impression.PMP? = nil
            
            var native: Request.Impression.Native?
            
            if let nativeAdRequirements = nativeAdRequirements,
               adType == .native,
               let requestData = try? JSONEncoder().encode(nativeAdRequirements),
               let requestString = String(data: requestData, encoding: .utf8)
            {
                native = Request.Impression.Native(request: requestString)
            }
            
            let impression = Request.Impression(
                //bidfloor: bidFloor ?? 0.01,
                //displaymanager: displayManager,
                id: storedImpressionId,
                tagid: storedImpressionId,
                //displaymanagerver: displayManagerVer,
                instl: adType.isFullscreen.intValue,
                banner: adType != .native ? banner : nil,
                video: adType == .interstitial || adType == .rewarded ? video : nil,
                native: native,
                ext: impExt,//data,
                pmp: pmp)
            
            let impressions = [impression]
            
            let publisher = Request.Application.Publisher(id: publisherID, ext: .init())
            
            var bundle = SystemInformation.shared.appBundleIdentifier
            
            if let bundleString = UserDefaults.standard.string(forKey: "bundle_config"), !bundleString.isEmpty {
                bundle = bundleString
            }
            
            let application = Request.Application(
                id: "5646234",
                bundle: bundle,
                ver: SystemInformation.shared.appVersion,
                publisher: publisher)
            
            let geo = BiddingConfig.Request.Device.Geo(
                lat: location?.coordinate.latitude,
                lon: location?.coordinate.longitude,
                accuracy: location?.horizontalAccuracy,
                type: 1,
                utcoffset: TimeService().timeZoneOffset)
            
            //TODO: DI
            let reachability: ReachabilityService = ReachabilityService()
            let connectionStatus = reachability.connectionStatus()
            
            let ext = Request.Device.Ext(ifv: SystemInformation.shared.idfv)
            
            var ifa = SystemInformation.shared.idfa ?? "ifa-ReportingTest-testMainWorkflow-XGcmO7"
            
            if let ifaString = UserDefaults.standard.string(forKey: "ifa_config"), !ifaString.isEmpty {
                ifa = ifaString
            }
            
            let device = Request.Device(
                ua: userAgent ?? "ua",
                make: "Apple",
                model: SystemInformation.shared.model,
                os: SystemInformation.shared.os,
                osv: SystemInformation.shared.systemVersion,
                hwv: SystemInformation.shared.hardwareVersion,
                language: (NSLocale.current as NSLocale).languageCode,
                ifa: ifa,
                dnt: 0,//SystemInformation.shared.dnt.intValue,
                devicetype: SystemInformation.shared.deviceType.rawValue,
                h: screenHeight,
                w: screenWidth,
                ppi: UIDevice.ppi,
                connectiontype: ConnectionType(reachabilityType: connectionStatus.connectionType).rawValue,
                lmt: nil, //SystemInformation.shared.lat.intValue,
                pxratio: Float(UIDevice.ppi),
                geo: geo,
                ext: ext)
            
//            let publisherUserID = CloudXTargeting.shared.userID
//            let yob = CloudXTargeting.shared.yob
//            let gender = CloudXTargeting.shared.gender
//            let keywords = CloudXTargeting.shared.keywords?.reduce("", { $0 + $1 + "," })
            var userDictionary: [String: String] = [:]
            var userPrebid: Request.User.Ext.Prebid? = nil
            
            if let hashedUserId = UserDefaults.standard.string(forKey: "hashedUserID"), !hashedUserId.isEmpty {
                userDictionary["cloudx"] = hashedUserId
                userPrebid = .init(buyeruids: userDictionary)
            }
            
//            if let hashedKey = UserDefaults.standard.string(forKey: "hashedKey"), let hashedValue = UserDefaults.standard.string(forKey: "hashedValue"), !hashedKey.isEmpty && !hashedValue.isEmpty {
//                userDictionary["hashedKey"] = hashedValue
//            }
            
            
            
            let user = Request.User(ext: .init(consent: "gdpr-consent-string", prebid: userPrebid))
            
            // Apply Privacy Settings
            let coppa = CloudXPrivacy.isAgeRestrictedUserSet ? CloudXPrivacy.isAgeRestrictedUser.intValue : nil
            let usPrivacyString = CloudXPrivacy.usPrivacyString
            let gdprApplies = CloudXPrivacy.gdprApplies?.intValue
            let tcString = CloudXPrivacy.tcfString
            
            let ccpa = CloudXPrivacy.isDoNotSellSet ? CloudXPrivacy.isDoNotSell.intValue : nil
            let gdpr = CloudXPrivacy.isUserConsentSet ? CloudXPrivacy.hasUserConsent.intValue : nil
            
            let iab = Request.Regulations.Ext.IAB(gdprApplies: gdprApplies, tcString: tcString, usPrivacyString: usPrivacyString)
            let regExt = Request.Regulations.Ext(iab: iab, gdpr: gdpr, ccpa: ccpa)
            
            let regulations = Request.Regulations(coppa: coppa, ext: regExt)
            
            self.id = UUID().uuidString
            self.imp = impressions
            self.app = application
            self.device = device
            self.user = user
            self.regs = regulations
            
            var adapterExtras: [String : [String : String]] = [:]
            for (key, value) in adapterInfo {
                adapterExtras[key.rawValue] = value
            }
            
            var prebidArray: [Ext.AdserverTargeting] = []
            
            if let userDict = UserDefaults.standard.dictionary(forKey: "userKeyValue") as? [String: String] {
                for key in userDict.keys {
                    prebidArray.append(Ext.AdserverTargeting(key: key, source: "bidrequest", value: userDict[key] ?? ""))
                }
            }
            
            let prebid = BiddingConfig.Request.Ext.PrebidDebug(debug: true, adservertargeting: prebidArray)
            self.ext = Ext(adapterExtras: adapterExtras, prebid: prebid)
        }
        
        private var _urlParams: [String: String]?
        var urlParams: [String: String] { _urlParams ?? [:] }
        
        //let tmax = 1000
        let id: String
        let imp: [Impression]
        let app: Application
        let device: Device
        let user: User?
        let regs: Regulations
        let ext: Ext?
        
        struct Regulations: Codable {
            let coppa: Int?
            let ext: Ext?
            
            struct Ext: Codable {
                
                struct IAB: Codable {
                    
                    enum CodingKeys: String, CodingKey {
                        case gdprApplies = "gdpr_tcfv2_gdpr_applies"
                        case tcString = "gdpr_tcfv2_tc_string"
                        case usPrivacyString = "ccpa_us_privacy_string"
                    }
                    
                    let gdprApplies: Int?
                    let tcString: String?
                    let usPrivacyString: String?
                    
                    init?(gdprApplies: Int?, tcString: String?, usPrivacyString: String?) {
                        if gdprApplies == nil && tcString == nil && usPrivacyString == nil {
                            return nil
                        }
                        
                        self.gdprApplies = gdprApplies
                        self.tcString = tcString
                        self.usPrivacyString = usPrivacyString
                    }
                }
                
                enum CodingKeys: String, CodingKey {
                    case gdpr = "gdpr_consent"
                    case ccpa = "ccpa_do_not_sell"
                    case iab = "iab"
                }
                
                let iab: IAB?
                let gdpr: Int?
                let ccpa: Int?
            }
        }
        
        struct Impression: Codable {
            //let bidfloor: Float
            let bidfloorcur = "USD"
            //let displaymanager: String
            let id: String
            let tagid: String
            //let displaymanagerver: String
            let exp: Int = 14400
            let instl: Int
            let secure: Int = 1
            let banner: Banner?
            let video: Video?
            let native: Native?
            let ext: Ext?//Data?
            let pmp: PMP?
            
            struct Banner: Codable {
                //let w, h: Int
                //let btype = [1, 4]
                //let pos: Int
                //let id = "1"
                //let api = [3, 5, 6, 7]
                let format: [Format]
                
                struct Format: Codable {
                    let w, h: Int
                }
            }
            
            struct Video: Codable {
                let w, h: Int
                let api = [3, 5, 6, 7]
                let protocols = [2, 3, 5, 6, 7, 8]
                let companiontype = [1, 2]
                let linearity = 1
                let mimes = [
                    "video/mp4",
                    "video/3gpp",
                    "video/3gpp2",
                    "video/x-m4v",
                    "video/quicktime",
                ]
                let placement: Int = 5
                let pos = 7
            }
            
            struct Native: Codable {
                let ver: String = "1.2"
                let request: String
            }
            
            struct Ext: Codable {
//                var skadn: SKadN?
//                var reward: Int?
                let prebid: StoredImpression
                //let bidder:
                
            
            struct AdserverTargeting: Codable {
                let key: String
                let source: String
                let value: String
            }
                
                
                struct StoredImpression: Codable {
                    let adservertargeting: [AdserverTargeting]
                    let storedimpression: Id
                }
                      
                struct Id: Codable {
                    let id: String
                }
                
                struct SKadN: Codable {
                    let sourceapp: String  //appbundle
                    let version: String = "2.0"
                    let versions: [String]
                    let skadnetlist: SkadNList
                    
                    struct SkadNList: Codable {
                        let addl: [String]
                        let excl: [String] = []  //???
                        let max: Int = 306
                    }
                }
            }
            
            struct PMP: Codable {
                let deals: [Deal]
                
                struct Deal: Codable {
                    let id : String
                }
            }
        }
        
        struct Application: Codable {
            struct Publisher: Codable {
                let id: String
                let ext: Ext
                struct Ext: Codable {}
            }
            
            let id: String
            let bundle, ver: String
            let publisher: Publisher
        }
        
        struct Device: Codable {
            let ua, make, model, os, osv, hwv, language, ifa: String
            let js = 1
            let dnt, devicetype, h, w, ppi, connectiontype: Int
            let lmt: Int?
            let pxratio: Float
            let geo: Geo
            let ext: Ext
            
            struct Geo: Codable {
                let lat: Double?
                let lon: Double?
                let accuracy: Double?
                let type: Int
                let utcoffset: Int  // Local time as the number +/- of minutes from UTC.
            }
            
            struct Ext: Codable {
                let ifv: String?
            }
        }
        
        struct User: Codable {
//            @NullEncodable var id: String?
//            var yob: Int?
//            var gender: CloudXTargeting.CloudXGender?
//            var keywords: String?
//            var data: [String : String]?
            
            var ext: Ext?
            
            struct Ext: Codable {
//                var age: Int?
//                var publisherUserID: String?
                var consent: String
                var prebid: Prebid?
                
                
                struct Prebid: Codable {
                    var buyeruids: [String: String]
                }
            }
        }
        
        struct Ext: Codable {
            enum CodingKeys: String, CodingKey {
                case adapterExtras = "adapter_extras"
                case prebid
            }
            
            let adapterExtras: [String : [String : String]]?
            let prebid: PrebidDebug?
            
            struct PrebidDebug: Codable {
                let debug: Bool?
                let adservertargeting: [AdserverTargeting]
            }
            
            struct AdserverTargeting: Codable {
                let key: String
                let source: String
                let value: String
            }
        }
    }
    
    struct Response: Decodable {
        let id, bidid: String?
        let seatbid: [Seatbid]
        let cur: String?
        let ext: Ext?
        
        private var bidQueue: [Bid] = []

        enum CodingKeys: String, CodingKey {
            case id, bidid, seatbid, cur, ext
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            bidid = try container.decodeIfPresent(String.self, forKey: .bidid)
            seatbid = try container.decode([Seatbid].self, forKey: .seatbid)
            cur = try container.decodeIfPresent(String.self, forKey: .cur)
            ext = try container.decodeIfPresent(Ext.self, forKey: .ext)
            bidQueue = seatbid.flatMap { $0.bid }.sorted()
        }
        
        mutating func getNextWinBid() -> Bid? {
            if bidQueue.isEmpty {
                return nil
            }
            
            let bid = bidQueue.removeFirst()
            print("[CloudX][BidResponse] Getting next win bid: id=\(bid.id ?? "nil"), impid=\(bid.impid ?? "nil"), rank=\(bid.ext?.cloudx?.rank ?? 0)")
            return bid
        }
        
        struct Seatbid: Decodable {
            var bid: [Bid]
            let seat: String?
        }
        
        //AdUnit
        struct Bid: Decodable {
            let id, adm, adid: String?
            let impid: String?
            let bundle, burl: String?
            let ext: Ext?
            let adomain: [String]?
            var price: Double
            var abTestId: Int64?
            var abTestGroup: String?
            let nurl, iurl: String?
            let cat: [String]?
            let cid, crid: String?
            let dealid: String?
            let w: Int?
            let h: Int?
            
            struct Ext: Decodable {
                
                let skadn: SKAd?
                let origbidcpm: Double?
                let origbidcur: String?
                let cloudx: CloudX?
                
                var adapter: String? {
                    cloudx?.meta?.adaptercode
                }
                
                struct CloudX: Decodable {
                    
                    enum CodingKeys: String, CodingKey {
                        case meta
                        case rank
                        case adapterExtras = "adapter_extras"
                    }
                    
                    let meta: Meta?
                    let rank: Int
                    let adapterExtras: [String : String]?
                    
                    struct Meta: Decodable {
                        let adaptercode: String
                    }
                    
                    enum BidResponseAdType: String, Decodable {
                        case banner
                        case interstitial
                        case rewarded
                        case mrec
                        case native
                    }
                }
                
                struct SKAd: Decodable {
                    let version: String
                    let network: String
                    let sourceidentifier: String?
                    let campaign: String?
                    let itunesitem: String
                    let productpageid: String?
                    let fidelities: [Fidelity]
                    let nonce: String?
                    let sourceapp: String
                    let timestamp: String?
                    let signature: String?
                    
                    struct Fidelity: Decodable {
                        let fidelity: Int
                        let nonce: String?
                        let signature: String
                        let timestamp: String
                    }
                }
            }
        }
        
        struct Ext: Decodable {
            // ... your Ext fields here ...
        }
    }
}

extension BiddingConfig.Response.Bid: Identifiable, Comparable {
    static func == (lhs: BiddingConfig.Response.Bid, rhs: BiddingConfig.Response.Bid) -> Bool {
        lhs.id == rhs.id
    }
    
    static func < (lhs: BiddingConfig.Response.Bid, rhs: BiddingConfig.Response.Bid) -> Bool {
        (lhs.ext?.cloudx?.rank ?? 0) < (rhs.ext?.cloudx?.rank ?? 0)
    }
    
}

/// A wrapper to decode any JSON value
struct DecodableValue: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([DecodableValue].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: DecodableValue].self) {
            value = dictValue.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
}
