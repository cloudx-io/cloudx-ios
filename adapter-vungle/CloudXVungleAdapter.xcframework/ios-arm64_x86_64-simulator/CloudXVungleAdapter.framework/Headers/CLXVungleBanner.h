//
//  CLXVungleBanner.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Vungle banner adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Vungle banner/MREC ads including loading, showing, and cleanup.
 * Supports standard banner sizes (320x50, 300x50, 728x90) and MREC (300x250).
 */
@interface CLXVungleBanner : CLXAdapterBanner <VungleBannerViewDelegate>

/**
 * CloudX adapter delegate for receiving ad events
 */
/**
 * The underlying Vungle banner view
 */
/**
 * SDK version of the Vungle SDK
 */
/**
 * Vungle placement ID for this ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 *
 * This is separate from `placementID` because:
 * - `placementID` is Vungle's internal identifier used by their SDK
 * - `adUnitName` is CloudX's human-readable identifier shown in error messages,
 *   logs, and delegate callbacks to help publishers identify which ad unit failed
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/**
 * Banner type (size)
 */
@property (nonatomic, assign, readonly) CLXBannerType bannerType;

/**
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, copy, nullable) NSString *bidPayload;

/**
 * Initializes a new Vungle banner adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle placement ID (nullable - validation deferred to load())
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param bidID The CloudX bid ID
 * @param type The banner type/size
 * @param delegate The CloudX adapter delegate
 * @return Initialized banner adapter
 * @since 1.4.0 adUnitName parameter added for better error messages
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type;

/**
 * Loads the banner ad
 */
/**
 * Shows the banner ad from the given view controller
 * @param viewController The view controller to show from
 */
/**
 * Destroys the banner ad and cleans up resources
 */
@end

NS_ASSUME_NONNULL_END
