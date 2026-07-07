//
//  CLXMagniteInterstitial.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Magnite interstitial adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Magnite interstitial ads including loading, showing, and cleanup.
 */
@interface CLXMagniteInterstitial : CLXAdapterInterstitial

/**
 * CloudX adapter delegate for receiving ad events.
 * Strong to keep the callback chain alive through the ad lifecycle. Cycle is broken in destroy.
 */
/**
 * SDK version of the Magnite SDK
 */
/**
 * Network name identifier
 */
/**
 * Magnite placement ID for this ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/**
 * Initializes a new Magnite interstitial adapter
 * @param bidPayload Ad markup from bid response (nil for waterfall, non-nil for bidding)
 * @param placementID The Magnite placement ID (nullable - validation deferred to load())
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param logger The CloudX adapter logger
 * @return Initialized interstitial adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

/**
 * Loads the interstitial ad
 */
/**
 * Shows the interstitial ad from the specified view controller
 * @param viewController The view controller to present from
 */
/**
 * Destroys the adapter and cleans up resources
 */
@end

NS_ASSUME_NONNULL_END
