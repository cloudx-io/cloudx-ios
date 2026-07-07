//
//  CLXVungleRewarded.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Vungle rewarded adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Vungle rewarded ads including loading, showing, and reward handling.
 */
@interface CLXVungleRewarded : CLXAdapterRewarded <VungleRewardedDelegate>

/**
 * Whether the rewarded ad is ready to be shown.
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
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, copy, nullable) NSString *bidPayload;

/**
 * Initializes a new Vungle rewarded adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle placement ID (nullable - validation deferred to load())
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @return Initialized rewarded adapter
 * @since 1.4.0 adUnitName parameter added for better error messages
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

/**
 * Loads the rewarded ad
 */
/**
 * Shows the rewarded ad from the specified view controller
 * @param viewController The view controller to present from
 */
/**
 * Destroys the adapter and cleans up resources
 */
@end

NS_ASSUME_NONNULL_END
