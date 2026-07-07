//
//  CLXMobileFuseAdView.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXDestroyable.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Banner / MREC adapter that wraps `MFBannerAd`.
 *
 * Track B contract: this initializer takes no delegate. The wrapper installs
 * itself as `adapter.delegate` after the factory returns, so the wrapper
 * receives load/show/click/impression fan-out exactly once per event.
 */
@interface CLXMobileFuseAdView : CLXAdapterAdView <IMFAdCallbackReceiver, CLXDestroyable>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                              type:(CLXBannerType)type
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
