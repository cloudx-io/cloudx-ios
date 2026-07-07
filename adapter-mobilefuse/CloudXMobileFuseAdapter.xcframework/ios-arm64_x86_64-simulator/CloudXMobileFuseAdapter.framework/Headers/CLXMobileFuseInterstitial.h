//
//  CLXMobileFuseInterstitial.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Interstitial adapter that wraps `MFInterstitialAd`.
 *
 * Track B contract: this initializer takes no delegate. The wrapper installs
 * itself as `adapter.delegate` after the factory returns, so the wrapper
 * receives load/show/click/impression fan-out exactly once per event.
 */
@interface CLXMobileFuseInterstitial : CLXAdapterInterstitial <IMFAdCallbackReceiver>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
