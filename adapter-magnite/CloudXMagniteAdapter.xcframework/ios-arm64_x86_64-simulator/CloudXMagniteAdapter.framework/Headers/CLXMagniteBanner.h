//
//  CLXMagniteBanner.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Magnite banner adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Magnite banner/MREC ads including loading, showing, and cleanup.
 * Supports standard banner (320x50) and MREC (300x250).
 */
@interface CLXMagniteBanner : NSObject <CLXAdapterBanner>

/**
 * CloudX adapter delegate for receiving ad events.
 * Strong to keep the callback chain alive through the ad lifecycle. Cycle is broken in destroy.
 */
@property (nonatomic, strong, nullable) id<CLXAdapterBannerDelegate> delegate;

/**
 * The underlying Magnite banner view
 */
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;

/**
 * SDK version of the Magnite SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Magnite placement ID for this ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/**
 * Banner type (size)
 */
@property (nonatomic, assign, readonly) CLXBannerType bannerType;

/**
 * Initializes a new Magnite banner adapter
 * @param bidPayload Ad markup from bid response (nil for waterfall, non-nil for bidding)
 * @param placementID The Magnite placement ID (nullable - validation deferred to load())
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param type The banner type/size
 * @param delegate The CloudX adapter delegate
 * @return Initialized banner adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                              type:(CLXBannerType)type
                          delegate:(nullable id<CLXAdapterBannerDelegate>)delegate;

/**
 * Loads the banner ad
 */
- (void)load;

/**
 * Shows the banner ad from the given view controller
 * @param viewController The view controller to show from
 */
- (void)showFromViewController:(UIViewController *)viewController;

/**
 * Destroys the banner ad and cleans up resources
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
