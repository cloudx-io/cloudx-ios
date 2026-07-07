//
//  CLXMobileFuseNative.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Native adapter that wraps `MFNativeAd`.
 *
 * Loads in two phases:
 *  1. -load: spins up a placement-bound MFNativeAd, attaches as receiver, and
 *     loads with the auction bid payload.
 *  2. -onAdLoaded: builds a CLXMobileFuseNativeAd around the resolved MFNativeAd
 *     and hands it back to the publisher via -didLoadNativeAd:extras:.
 */
@interface CLXMobileFuseNative : CLXAdapterNative <IMFAdCallbackReceiver>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
