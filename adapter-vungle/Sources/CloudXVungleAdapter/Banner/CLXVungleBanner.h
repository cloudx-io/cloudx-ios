//
//  CLXVungleBanner.h
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

// Conditional import for CloudXCore header
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
@interface CLXVungleBanner : NSObject <VungleBannerViewDelegate, CLXAdapterBanner, CLXDestroyable>

/**
 * CloudX adapter delegate for receiving ad events
 */
@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;

/**
 * Flag indicating if the ad loading timed out
 */
@property (nonatomic, assign) BOOL timeout;

/**
 * The underlying Vungle banner view
 */
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;

/**
 * SDK version of the Vungle SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Timeout interval for ad loading
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * Vungle placement ID for this ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX bid ID
 */
@property (nonatomic, copy, readonly) NSString *bidID;

/**
 * Banner type (size)
 */
@property (nonatomic, assign, readonly) CLXBannerType bannerType;

/**
 * View controller for presenting the banner
 */
@property (nonatomic, weak, readonly, nullable) UIViewController *viewController;

/**
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, copy, nullable) NSString *bidPayload;

/**
 * Initializes a new Vungle banner adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle placement ID
 * @param bidID The CloudX bid ID
 * @param type The banner type/size
 * @param viewController The view controller for presenting the banner
 * @param delegate The CloudX adapter delegate
 * @return Initialized banner adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type
                    viewController:(UIViewController *)viewController
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

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
