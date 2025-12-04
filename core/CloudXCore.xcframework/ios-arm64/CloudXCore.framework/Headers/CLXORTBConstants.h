//
//  CLXORTBConstants.h
//  CloudXCore
//
//  OpenRTB 2.5 constant definitions for bid request compliance.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Ad Position (ORTB 2.5 Section 5.4)

/**
 * OpenRTB 2.5 Ad Position values.
 * Indicates the position of the ad on the screen.
 *
 * @see https://www.iab.com/wp-content/uploads/2016/03/OpenRTB-API-Specification-Version-2-5-FINAL.pdf
 */
typedef NS_ENUM(NSInteger, CLXORTBAdPosition) {
    /// Position unknown
    CLXORTBAdPositionUnknown = 0,
    
    /// Above the fold - visible without scrolling
    CLXORTBAdPositionAboveTheFold = 1,
    
    /// DEPRECATED - May or may not be initially visible depending on screen size
    CLXORTBAdPositionDeprecated = 2,
    
    /// Below the fold - requires scrolling to be visible
    CLXORTBAdPositionBelowTheFold = 3,
    
    /// Header position (typically top of screen)
    CLXORTBAdPositionHeader = 4,
    
    /// Footer position (typically bottom of screen)
    CLXORTBAdPositionFooter = 5,
    
    /// Sidebar position
    CLXORTBAdPositionSidebar = 6,
    
    /// Full screen (interstitials, rewarded)
    CLXORTBAdPositionFullScreen = 7
};

#pragma mark - Device Type (ORTB 2.5 Section 5.21)

/**
 * OpenRTB 2.5 Device Type values.
 */
typedef NS_ENUM(NSInteger, CLXORTBDeviceType) {
    /// Mobile/Tablet (general)
    CLXORTBDeviceTypeMobileTablet = 1,
    
    /// Personal Computer
    CLXORTBDeviceTypePC = 2,
    
    /// Connected TV
    CLXORTBDeviceTypeConnectedTV = 3,
    
    /// Phone
    CLXORTBDeviceTypePhone = 4,
    
    /// Tablet
    CLXORTBDeviceTypeTablet = 5,
    
    /// Connected Device
    CLXORTBDeviceTypeConnectedDevice = 6,
    
    /// Set Top Box
    CLXORTBDeviceTypeSetTopBox = 7
};

#pragma mark - Connection Type (ORTB 2.5 Section 5.22)

/**
 * OpenRTB 2.5 Connection Type values.
 */
typedef NS_ENUM(NSInteger, CLXORTBConnectionType) {
    /// Unknown
    CLXORTBConnectionTypeUnknown = 0,
    
    /// Ethernet
    CLXORTBConnectionTypeEthernet = 1,
    
    /// WiFi
    CLXORTBConnectionTypeWifi = 2,
    
    /// Cellular Network - Unknown Generation
    CLXORTBConnectionTypeCellularUnknown = 3,
    
    /// Cellular Network - 2G
    CLXORTBConnectionTypeCellular2G = 4,
    
    /// Cellular Network - 3G
    CLXORTBConnectionTypeCellular3G = 5,
    
    /// Cellular Network - 4G
    CLXORTBConnectionTypeCellular4G = 6
};

#pragma mark - Banner Ad Type (ORTB 2.5 Section 5.2)

/**
 * OpenRTB 2.5 Banner Ad Type values.
 */
typedef NS_ENUM(NSInteger, CLXORTBBannerAdType) {
    /// XHTML Text Ad
    CLXORTBBannerAdTypeXHTMLText = 1,
    
    /// XHTML Banner Ad
    CLXORTBBannerAdTypeXHTMLBanner = 2,
    
    /// JavaScript Ad
    CLXORTBBannerAdTypeJavaScript = 3,
    
    /// iframe
    CLXORTBBannerAdTypeIframe = 4
};

#pragma mark - Video Placement Type (ORTB 2.5 Section 5.9)

/**
 * OpenRTB 2.5 Video Placement Type values.
 */
typedef NS_ENUM(NSInteger, CLXORTBVideoPlacement) {
    /// In-Stream (played before, during, or after streaming video content)
    CLXORTBVideoPlacementInStream = 1,
    
    /// In-Banner (exists within a web banner)
    CLXORTBVideoPlacementInBanner = 2,
    
    /// In-Article (loads between paragraphs of editorial content)
    CLXORTBVideoPlacementInArticle = 3,
    
    /// In-Feed (found in content, social, or product feeds)
    CLXORTBVideoPlacementInFeed = 4,
    
    /// Interstitial/Slider/Floating (covers entire or portion of screen)
    CLXORTBVideoPlacementInterstitial = 5
};

#pragma mark - Helper Functions

/**
 * Converts CLXORTBAdPosition to NSNumber for JSON serialization.
 */
NS_INLINE NSNumber * CLXORTBAdPositionToNumber(CLXORTBAdPosition position) {
    return @(position);
}

/**
 * Returns a human-readable string for an ad position value.
 */
NS_INLINE NSString * CLXORTBAdPositionDescription(CLXORTBAdPosition position) {
    switch (position) {
        case CLXORTBAdPositionUnknown: return @"Unknown";
        case CLXORTBAdPositionAboveTheFold: return @"Above the Fold";
        case CLXORTBAdPositionDeprecated: return @"Deprecated";
        case CLXORTBAdPositionBelowTheFold: return @"Below the Fold";
        case CLXORTBAdPositionHeader: return @"Header";
        case CLXORTBAdPositionFooter: return @"Footer";
        case CLXORTBAdPositionSidebar: return @"Sidebar";
        case CLXORTBAdPositionFullScreen: return @"Full Screen";
        default: return @"Unknown";
    }
}

NS_ASSUME_NONNULL_END

