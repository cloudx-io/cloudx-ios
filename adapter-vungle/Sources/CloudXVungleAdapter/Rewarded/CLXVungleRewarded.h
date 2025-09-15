//
//  CLXVungleRewarded.h
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
 * Vungle rewarded adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Vungle rewarded ads including loading, showing, and reward handling.
 */
@interface CLXVungleRewarded : NSObject <VungleRewardedDelegate, CLXAdapterRewarded>

/**
 * CloudX adapter delegate for receiving ad events
 */
@property (nonatomic, weak, nullable) id<CLXAdapterRewardedDelegate> delegate;

/**
 * The underlying Vungle rewarded ad instance
 */
@property (nonatomic, strong, nullable) VungleRewarded *rewarded;

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
 * Whether the ad is ready to be shown
 */
@property (nonatomic, assign, readonly) BOOL isReady;

/**
 * Vungle placement ID for this ad
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
 * Initializes a new Vungle rewarded adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle placement ID
 * @param bidID The CloudX bid ID
 * @param delegate The CloudX adapter delegate
 * @return Initialized rewarded adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate;

/**
 * Loads the rewarded ad
 */
- (void)load;

/**
 * Shows the rewarded ad from the specified view controller
 * @param viewController The view controller to present from
 */
- (void)showFromViewController:(UIViewController *)viewController;

/**
 * Destroys the adapter and cleans up resources
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
