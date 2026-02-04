//
//  CLXVungleInterstitial.h
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
 * Vungle interstitial adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Vungle interstitial ads including loading, showing, and cleanup.
 */
@interface CLXVungleInterstitial : NSObject <VungleInterstitialDelegate, CLXAdapterInterstitial>

/**
 * CloudX adapter delegate for receiving ad events
 */
@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;

/**
 * Flag indicating if the ad loading timed out
 */
@property (nonatomic, assign) BOOL timeout;

/**
 * The underlying Vungle interstitial ad instance
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
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, copy, nullable) NSString *bidPayload;

/**
 * Initializes a new Vungle interstitial adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle placement ID (nullable - validation deferred to load())
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param bidID The CloudX bid ID
 * @param delegate The CloudX adapter delegate (nullable - validation deferred to load())
 * @return Initialized interstitial adapter
 * @discussion As of v1.3.0, placementID and delegate can be nil. Validation occurs in load()
 *             and errors are reported via delegate callback.
 * @since 1.3.0 placementID and delegate parameters are now nullable
 * @since 1.4.0 adUnitName parameter added for better error messages
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(nullable id<CLXAdapterInterstitialDelegate>)delegate;

/**
 * Loads the interstitial ad
 */
- (void)load;

/**
 * Shows the interstitial ad from the specified view controller
 * @param viewController The view controller to present from
 */
- (void)showFromViewController:(UIViewController *)viewController;

/**
 * Destroys the adapter and cleans up resources
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
