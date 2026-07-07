//
//  CLXPangleAppOpen.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Pangle app open adapter.
 *
 * Backs the CloudX app-open format with Pangle's dedicated `PAGLAppOpenAd`.
 * Manages the lifecycle of Pangle app open ads including loading, showing,
 * and cleanup. App open reuses the interstitial adapter contract, so this
 * subclasses CLXAdapterInterstitial.
 */
@interface CLXPangleAppOpen : CLXAdapterInterstitial <PAGLAppOpenAdDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
