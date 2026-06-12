//
//  CLXVungleNative.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Vungle native adapter — conforms to `CLXAdapterNative` and acts as
 * `VungleNativeDelegate` for the underlying `VungleNative` SDK instance.
 *
 * Serves both the native-in-banner/MREC and standalone native paths. The
 * adapter requires a bid payload and does not support waterfall.
 */
@interface CLXVungleNative : CLXAdapterNative <VungleNativeDelegate>

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                   bidExpirationMs:(NSInteger)bidExpirationMs NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
