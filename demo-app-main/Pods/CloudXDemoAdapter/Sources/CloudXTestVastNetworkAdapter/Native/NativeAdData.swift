//
//  NativeAdData.swift
//
//
//  Created by bkorda on 09.05.2024.
//

import Foundation
import CloudXCore

struct NativeAdData: Decodable {
    let native: Native
    
    var nativeAdType: CloudXNativeTemplate {
        if !self.native.assets.compactMap({ $0.video }).isEmpty ||
            !self.native.assets.filter({ $0.img != nil }).filter({ $0.id == NativeAdRequirements.NativeImageAssetID.main.rawValue }).isEmpty {
            return .medium
        } else {
            return .small
        }
    }
    
    var mainImgURL: String? {
        return self.native.assets.filter({ $0.img != nil }).first(where :{ $0.id == NativeAdRequirements.NativeImageAssetID.main.rawValue })?.img?.url
    }
    
    var appIconURL: String? {
        return self.native.assets.filter({ $0.img != nil }).filter({ $0.id == NativeAdRequirements.NativeImageAssetID.icon.rawValue }).first?.img?.url
    }
    
    var title: String? {
        return self.native.assets.first { $0.title != nil }?.title?.text
    }
    
    var description: String? {
        return self.native.assets.first { $0.id == NativeAdRequirements.NativeDataAssetID.description.rawValue }?.data?.value
    }
    
    var sponsored: String? {
        return self.native.assets.first { $0.id == NativeAdRequirements.NativeDataAssetID.sponsored.rawValue }?.data?.value
    }
    
    var rating: String? {
        return self.native.assets.first { $0.id == NativeAdRequirements.NativeDataAssetID.rating.rawValue }?.data?.value
    }
    
    var ctatext: String? {
        return self.native.assets.first { $0.id == NativeAdRequirements.NativeDataAssetID.ctaTitle.rawValue }?.data?.value
    }
    
    var ctaLink: String? {
        return self.native.link.flatMap { $0.url } ?? self.native.assets.first { $0.link != nil }?.link?.url
    }
    
    struct Native: Decodable {
        let ver: String?
        let assets: [Asset]
        let link: Link?
        let eventtrackers: [EventTracker]?
        let imptrackers: [String]?
        let privacy: String?
        
        struct Asset: Decodable {
            let id: Int
            let required: Int?
            let img: Img?
            let title: Title?
            let video: Video?
            let data: Data?
            let link: Link?
            
            struct Img: Decodable {
                let type: ImageType?
                let url: String
                let w: Int
                let h: Int
                
                enum ImageType: Int, Decodable {
                    case icon = 1
                    case main = 3
                }
            }
            
            struct Title: Decodable {
                let text: String
                let len: Int?
            }
            
            struct Video: Decodable {
                let vasttag: String
            }
            
            struct Data: Decodable {
                let type: DataType?
                let len: Int?
                let value: String
                
                enum DataType: Int, Decodable {
                    case sponsored = 1
                    case desc
                    case rating
                    case likes
                    case downloads
                    case price
                    case saleprice
                    case phone
                    case address
                    case desc2
                    case displayurl
                    case ctatext
                }
            }
        }
        
        struct Link: Decodable {
            let url: String
            let clicktrackers: [String]?
            let fallback: String?
        }
        
        struct EventTracker: Decodable {
            let event: TrackerEventType
            let method: EventTrackingMethod
            let url: String
            let customdata: [String: String]?
            
            enum TrackerEventType: Int, Decodable {
                case impression = 1
                case viewableMRC50
                case viewableMRC100
                case viewableVideo50
            }
            
            enum EventTrackingMethod: Int, Decodable {
                case img = 1
                case js
            }
        }
    }
}
