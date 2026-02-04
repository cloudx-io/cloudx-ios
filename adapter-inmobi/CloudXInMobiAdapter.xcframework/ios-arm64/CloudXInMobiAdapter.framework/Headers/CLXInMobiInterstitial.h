//
//  CLXInMobiInterstitial.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * InMobi interstitial adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of InMobi interstitial ads including loading, showing, and cleanup.
 */
@interface CLXInMobiInterstitial : NSObject <IMInterstitialDelegate, CLXAdapterInterstitial>

/**
 * CloudX adapter delegate for receiving ad events
 */
@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;

/**
 * Flag indicating if the ad loading timed out
 */
@property (nonatomic, assign) BOOL timeout;

/**
 * The underlying InMobi interstitial ad instance
 */
@property (nonatomic, strong, nullable) IMInterstitial *interstitial;

/**
 * SDK version of the InMobi SDK
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
 * InMobi placement ID for this ad
 */
@property (nonatomic, assign, readonly) long long placementID;

/**
 * CloudX ad unit name for error messages and logging.
 *
 * This is separate from `placementID` because:
 * - `placementID` is InMobi's internal numeric identifier used by their SDK
 * - `adUnitName` is CloudX's human-readable identifier shown in error messages,
 *   logs, and delegate callbacks to help publishers identify which ad unit failed
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/**
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, strong, nullable) NSData *bidPayload;

/**
 * Initializes a new InMobi interstitial adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The InMobi placement ID
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param bidID The CloudX bid ID
 * @param delegate The CloudX adapter delegate
 * @return Initialized interstitial adapter
 * @since 1.4.0 adUnitName parameter added for better error messages
 */
- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

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

