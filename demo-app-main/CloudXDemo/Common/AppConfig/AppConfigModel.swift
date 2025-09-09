//
//  AppConfigModel.swift
//  CloudXDemo
//
//  Created by Xenoss on 03.04.2025.
//


import Foundation

var appConfigModel: AppConfigModel?

let appConfigModelJson = """
{
  "layout": {
    "screens": {
      "banner": {
        "standard": [
          {
            "placementName": "defaultBanner",
            "adType": "banner",
            "size": "standard"
          },
          {
            "placementName": "MyDemoPlacement",
            "adType": "banner",
            "size": "standard"
          }
        ],
        "mrec": [
          {
            "placementName": "defaultMrec",
            "adType": "mrec"
          }
        ]
      },
      "native": {
        "small": [
          {
            "placementName": "defaultNativeSmall",
            "adType": "native",
            "size": "small"
          }
        ],
        "medium": [
          {
            "placementName": "defaultNativeMedium",
            "adType": "native",
            "size": "medium"
          }
        ]
      },
      "interstitial": {
        "default": [
          {
            "placementName": "defaultInterstitial",
            "adType": "interstitial"
          }
        ]
      },
      "rewarded": {
        "default": [
          {
            "placementName": "defaultRewarded",
            "adType": "rewarded"
          }
        ]
      }
    }
  },
  "SDKConfiguration": {
    "location": {
      "type": "V2",
      "path": "https://your-server.com/demo-app-config"
    }
  }
}
"""

//var defaultConfigModel: AppConfigModel {
//    set {
//        
//    }
//    get {
//        if let jsonData = appConfigModelJson.data(using: .utf8) {
//            do {
//                let model = try JSONDecoder().decode(AppConfigModel.self, from: jsonData)
//                return model
//            } catch {
//                print(error)
//            }
//        }
//        let jsonData = appConfigModelJson.data(using: .utf8)!
//        return AppConfigModel()
//        
//    }
//}
let defaultConfigModel = AppConfigModel(
    layout: AppConfigModel.LayoutModel(
        screens: AppConfigModel.LayoutModel.ScreensModel(
            banner: AppConfigModel.LayoutModel.ScreensModel.BannerModel(
                standard: [AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "MyDemoPlacement", adType: "banner", size: "standard"),
                           AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "defaultBanner", adType: "banner", size: "standard"),
                           ],
                mrec: [AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "defaultMrec", adType: "mrec", size: nil)],
                def: nil),
            native: AppConfigModel.LayoutModel.ScreensModel.NativeModel(
                small: [AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "defaultNativeSmall", adType: "native", size: "small")],
                medium: [AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "defaultNativeMedium", adType: "native", size: "medium")],
                def: nil),
            interstitial: AppConfigModel.LayoutModel.ScreensModel.InterstitialModel(
                def: [AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "defaultInterstitial", adType: "interstitial", size: nil)]),
            rewarded: AppConfigModel.LayoutModel.ScreensModel.RewardedModel(
                def: [AppConfigModel.LayoutModel.AddTypeModel(id: UUID(), placementName: "defaultRewarded", adType: "rewarded", size: nil)]))),
    sdkConfiguration: AppConfigModel.SDKConfigurationModel(ifa: "", bundle: "com.example.demoapp", location: AppConfigModel.SDKConfigurationModel.LocationModel(type: "V2", path: "https://your-server.com/demo-app-config"), userInfo: AppConfigModel.SDKConfigurationModel.UserInfo(userEmailHashed: "29060c8606954ec90fbcde825b2783b0b9261585793db9dfcbe6b870a05a9ee3", userEmail: nil, userIdRegisteredAtMS: 0, hashAlgo: "sha256"), keyValues: nil, hashedKeyValues: nil,  bidderKeyValues: nil))

struct AppConfigModel: Codable {
    var layout: LayoutModel
    let sdkConfiguration: SDKConfigurationModel
    
    struct LayoutModel: Codable {
        var screens: ScreensModel
        
        struct ScreensModel: Codable {
            var banner: BannerModel
            let native: NativeModel
            let interstitial: InterstitialModel
            let rewarded: RewardedModel
            
            struct BannerModel: Codable {
                var standard: [AddTypeModel]
                var mrec: [AddTypeModel]
                let def: [AddTypeModel]?
            }
            
            struct NativeModel: Codable {
                let small: [AddTypeModel]
                let medium: [AddTypeModel]
                let def: [AddTypeModel]?
            }
            
            struct InterstitialModel: Codable {
                let def: [AddTypeModel]?
                
                enum CodingKeys: String, CodingKey {
                    case def = "default"
                }
            }
            
            struct RewardedModel: Codable {
                let def: [AddTypeModel]?
                
                enum CodingKeys: String, CodingKey {
                    case def = "default"
                }
            }
            
        }
        
        struct AddTypeModel: Codable {
            var id: UUID?
            var placementName: String
            let adType: String
            let size: String?
            
            init(id: UUID? = nil,
                 placementName: String,
                 adType: String,
                 size: String?) {
                self.id = id
                self.placementName = placementName
                self.adType = adType
                self.size = size
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                placementName = try container.decode(String.self, forKey: .placementName)
                adType = try container.decode(String.self, forKey: .adType)
                do {
                    id = try container.decode(UUID.self, forKey: .id)
                } catch {
                    id = UUID()
                }
                do {
                    size = try container.decode(String?.self, forKey: .size)
                } catch {
                    size = nil
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case id
                case placementName
                case adType
                case size
            }
        }
    }
    
    struct SDKConfigurationModel: Codable {
        let ifa: String?
        let bundle: String?
        let location: LocationModel
        let userInfo: UserInfo?
        let keyValues: [String: String]?
        let hashedKeyValues: [String: String]?
        let bidderKeyValues: [String: [String: String]]?
        
        struct LocationModel: Codable {
            let type: String
            let path: String
        }
        
        struct UserInfo: Codable {
            let userEmailHashed: String?
            let userEmail: String?
            let userIdRegisteredAtMS: Int
            let hashAlgo: String
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case layout
        case sdkConfiguration = "SDKConfiguration"
    }
}
