//
//  CLXVungleAppOpen.h
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
 * Vungle App Open adapter implementing CloudX adapter protocol.
 * App Open ads use the same Vungle interstitial implementation but with dedicated App Open placements.
 * These ads are typically shown when the app is launched or brought to the foreground.
 */
@interface CLXVungleAppOpen : NSObject <VungleInterstitialDelegate, CLXAdapterInterstitial>

/**
 * CloudX adapter delegate for receiving ad events
 */
@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;

/**
 * The underlying Vungle interstitial ad instance (used for App Open)
 */
@property (nonatomic, strong, nullable) VungleInterstitial *interstitial;

/**
 * SDK version of the Vungle SDK
 */
@property (nonatomic, strong, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, strong, readonly) NSString *network;

/**
 * Ad ID from bid response
 */
@property (nonatomic, strong, readonly) NSString *bidID;

/**
 * Vungle placement ID for this App Open ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, copy, nullable) NSString *bidPayload;

/**
 * Timeout interval for ad loading
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * Initializes a new Vungle App Open adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle App Open placement ID
 * @param bidID The CloudX bid ID
 * @param delegate The CloudX adapter delegate
 * @return Initialized App Open adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

/**
 * Loads the App Open ad
 */
- (void)load;

/**
 * Shows the App Open ad from the specified view controller
 * @param viewController The view controller to present from
 */
- (void)showFromViewController:(UIViewController *)viewController;

/**
 * Destroys the adapter and cleans up resources
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
