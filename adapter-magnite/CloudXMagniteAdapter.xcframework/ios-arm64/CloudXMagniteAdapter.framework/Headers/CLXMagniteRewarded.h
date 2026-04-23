//
//  CLXMagniteRewarded.h
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
 * Magnite rewarded adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Magnite rewarded ads including loading, showing, and reward handling.
 */
@interface CLXMagniteRewarded : NSObject <CLXAdapterRewarded>

/**
 * CloudX adapter delegate for receiving ad events.
 * Strong to keep the callback chain alive through the ad lifecycle. Cycle is broken in destroy.
 */
@property (nonatomic, strong, nullable) id<CLXAdapterRewardedDelegate> delegate;

/**
 * SDK version of the Magnite SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Magnite placement ID for this ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/**
 * Initializes a new Magnite rewarded adapter
 * @param bidPayload Ad markup from bid response (nil for waterfall, non-nil for bidding)
 * @param placementID The Magnite placement ID (nullable - validation deferred to load())
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param bidID The CloudX bid ID
 * @param delegate The CloudX adapter delegate
 * @return Initialized rewarded adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(nullable id<CLXAdapterRewardedDelegate>)delegate;

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
