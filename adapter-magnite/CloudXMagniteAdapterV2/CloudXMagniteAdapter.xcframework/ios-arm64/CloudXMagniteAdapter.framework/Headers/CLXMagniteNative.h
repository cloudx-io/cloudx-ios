//
//  CLXMagniteNative.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Magnite native adapter implementing the CloudX CLXAdapterNative contract.
 * Manages the lifecycle of a Magnite native ad load, including impression/click
 * fan-out and view-registration cleanup.
 */
@interface CLXMagniteNative : CLXAdapterNative

/**
 * Magnite placement ID for this ad.
 */
@property (nonatomic, copy, readonly, nullable) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

/// Whether the requested native template requires a primary media asset.
@property (nonatomic, assign, readonly) BOOL requiresMainMedia;

/**
 * Initializes a new Magnite native adapter.
 * @param bidPayload Ad markup from bid response (nil for waterfall, non-nil for bidding)
 * @param placementID The Magnite placement ID (nullable - validation deferred to load)
 * @param adUnitName The CloudX placement name for error messages (nullable)
 * @param localExtraParameters Publisher-supplied local extras (e.g. native video options)
 * @param logger The CloudX adapter logger
 * @return Initialized native adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        placementID:(nullable NSString *)placementID
                         adUnitName:(nullable NSString *)adUnitName
               localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                             logger:(id<CLXAdapterLogger>)logger;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                        placementID:(nullable NSString *)placementID
                         adUnitName:(nullable NSString *)adUnitName
               localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                  requiresMainMedia:(BOOL)requiresMainMedia
                             logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
