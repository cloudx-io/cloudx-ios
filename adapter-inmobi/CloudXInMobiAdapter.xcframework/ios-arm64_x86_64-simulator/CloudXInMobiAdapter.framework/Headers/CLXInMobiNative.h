//
//  CLXInMobiNative.h
//  CloudXInMobiAdapter
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK-Swift.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * InMobi native adapter — conforms to `CLXAdapterNative` and `IMNativeDelegate`
 * for the underlying `IMNative` SDK handle.
 *
 * Bidding-only: waterfall is not supported in the native-in-banner pipeline.
 */
@interface CLXInMobiNative : CLXAdapterNative <IMNativeDelegate>

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                        adUnitName:(nullable NSString *)adUnitName
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
