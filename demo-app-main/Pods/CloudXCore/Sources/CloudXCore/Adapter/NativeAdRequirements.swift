//
//  NativeAdRequirements.swift
//  CloudXCore
//
//  Created by bkorda on 09.05.2024.
//

import Foundation

/// Struct that represents the requirements for a native ad in  bid request.
public struct NativeAdRequirements: Encodable {
    
    /// Identifier of the native ad image assets
    public enum NativeImageAssetID: Int {
        /// Main image asset ID
        case main = 1
        /// Icon image asset ID
        case icon = 2
    }
    
    /// Identifier of the native ad data assets.
    public enum NativeDataAssetID: Int {
        /// Call to action text asset ID
        case ctaTitle = 3
        /// Description text asset ID
        case description
        /// Rating text asset ID
        case rating
        /// Sponsored text asset ID
        case sponsored
    }
    
    /// Identifier of the native ad title assets.
    public enum NativeTitleAssetID: Int {
        /// Title text asset ID
        case title = 7
    }
    
    /// Identifier of the native ad video assets.
    public enum NativeVideoAssetID: Int {
        /// Video asset ID
        case video = 8
    }
    
    /// Native ad type.
    public enum NativeAdType {
        /// Small native ad
        case small
        /// Medium native ad
        case medium
        /// Unknown native ad type
        case unknown
    }
    
    private static var appIconAsset: Asset {
        let appIcon = Asset.Img(type: .icon, wmin: 1, hmin: 1)
        return Asset(id: NativeImageAssetID.icon.rawValue, required: 1, img: appIcon, title: nil, video: nil, data: nil)
    }
    
    private static var mainImageAsset: Asset {
        let mainImage = Asset.Img(type: .main, wmin: 1, hmin: 1)
        return Asset(id: NativeImageAssetID.main.rawValue, required: 1, img: mainImage, title: nil, video: nil, data: nil)
    }
    
    private static var videoAsset: Asset {
        let video = Asset.Video(mimes: ["video/mp4", "video/quicktime"], minduration: 1, maxduration: 30)
        return Asset(id: NativeVideoAssetID.video.rawValue, required: 0, img: nil, title: nil, video: video, data: nil)
    }
    
    private static var titleAsset: Asset {
        let title = Asset.Title(len: 25)
        return Asset(id: NativeTitleAssetID.title.rawValue, required: 1, img: nil, title: title, video: nil, data: nil)
    }
    
    private static var sponsoredTextAsset: Asset {
        let description = Asset.Data(type: .sponsored, len: 30)
        return Asset(id: NativeDataAssetID.sponsored.rawValue, required: 0, img: nil, title: nil, video: nil, data: description)
    }
    
    private static var descriptionTextAsset: Asset {
        let description = Asset.Data(type: .desc, len: 90)
        return Asset(id: NativeDataAssetID.description.rawValue, required: 0, img: nil, title: nil, video: nil, data: description)
    }
    
    private static var ratingAsset: Asset {
        let rating = Asset.Data(type: .rating, len: 10)
        return Asset(id: NativeDataAssetID.rating.rawValue, required: 1, img: nil, title: nil, video: nil, data: rating)
    }
    
    private static var ctaAsset: Asset {
        let cta = Asset.Data(type: .ctatext, len: 15)
        return Asset(id: NativeDataAssetID.ctaTitle.rawValue, required: 1, img: nil, title: nil, video: nil, data: cta)
    }
    
    private static var eventTrackers: [NativeAdRequirements.EventTracker] = [
        NativeAdRequirements.EventTracker(event: .impression, methods: [.img]),
        NativeAdRequirements.EventTracker(event: .viewableMRC50, methods: [.img]),
        NativeAdRequirements.EventTracker(event: .viewableMRC100, methods: [.img]),
        NativeAdRequirements.EventTracker(event: .viewableVideo50, methods: [.img]),
    ]
    
    
    /// Initializer for native ad requirements.
    /// - Parameters:
    ///   - assets: array of assets required for the native ad
    ///   - context: context of the native ad (content, social, product, custom)
    ///   - privacy: privacy policy of the native ad
    ///   - plcmttype: placement type of the native ad
    ///   - eventtrackers: array of event trackers for the native ad
    public init(
        assets: [NativeAdRequirements.Asset], context: NativeAdRequirements.NativeAdContext, privacy: Int,
        plcmttype: NativeAdRequirements.PlacementType? = nil, eventtrackers: [NativeAdRequirements.EventTracker]? = nil
    ) {
        self.assets = assets
        self.context = context
        self.plcmttype = plcmttype
        self.eventtrackers = eventtrackers
        self.privacy = privacy
    }
    
    /// Prebuilt native ad request for small native ad.
    public static var smallNativeRequest: Self {
        NativeAdRequirements(
            assets: [appIconAsset, titleAsset, sponsoredTextAsset, descriptionTextAsset, ratingAsset, ctaAsset], context: .content, privacy: 1,
            eventtrackers: eventTrackers)
    }
    
    /// Prebuilt native ad request for medium native ad.
    public static var mediumNativeRequest: Self {
        return NativeAdRequirements(
            assets: [appIconAsset, mainImageAsset, videoAsset, titleAsset, sponsoredTextAsset, descriptionTextAsset, ratingAsset, ctaAsset], context: .content,
            privacy: 1, eventtrackers: eventTrackers)
    }
    
//    /// Returns the native ad type based on the assets
//    public var adType: NativeAdType {
//        if assets.compactMap({ $0.video }).count != 0 || assets.filter({ $0.img?.type == .main }).count != 0 {
//            return .medium
//        } else {
//            return .small
//        }
//    }
//    
    /// Native ad context based on IAB OpenRTB 2.5
    public enum NativeAdContext: Int, Encodable {
        case content = 1
        case social
        case product
    }
    
    let ver: String = "1.2"
    let assets: [Asset]
    let context: NativeAdContext
    let plcmttype: PlacementType?
    let eventtrackers: [EventTracker]?
    let privacy: Int
    
    /// Native ad placement type based on IAB OpenRTB 2.5.
    public enum PlacementType: Int, Encodable {
        case infeed = 1
        case atomic
        case bannerStyle
        case widget
    }
    
    /// Struct present native ad asset.
    public struct Asset: Encodable {
        let id: Int
        let required: Int
        let img: Img?
        let title: Title?
        let video: Video?
        let data: Data?
        
        /// Struct present native ad image asset.
        public struct Img: Encodable {
            let type: ImageType
            let wmin: Int
            let hmin: Int
            
            /// Enum for image type asset of native ads in bid request.
            public enum ImageType: Int, Encodable {
                /// Icon image type
                case icon = 1
                /// Main image type
                case main = 3
            }
        }
        
        /// Struct present native ad title asset.
        public struct Title: Encodable {
            let len: Int
        }
        
        /// Struct present native ad video asset.
        public struct Video: Encodable {
            let mimes: [String]
            let minduration: Int
            let maxduration: Int
            let protocols: [Int] = [2, 3, 5, 6, 7, 8]
        }
        
        /// Struct present native ad data asset.
        public struct Data: Encodable {
            let type: DataType
            let len: Int
            
            /// Enum for data type asset of native ads in bid request based on IAB OpenRTB 2.5.
            public enum DataType: Int, Encodable {
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
    
    /// Struct present native ad event tracker.
    public struct EventTracker: Encodable {
        let event: TrackerEventType
        let methods: [EventTrackingMethod]
        
        enum TrackerEventType: Int, Encodable {
            case impression = 1
            case viewableMRC50
            case viewableMRC100
            case viewableVideo50
        }
        
        enum EventTrackingMethod: Int, Encodable {
            case img = 1
            case js
        }
    }
}
