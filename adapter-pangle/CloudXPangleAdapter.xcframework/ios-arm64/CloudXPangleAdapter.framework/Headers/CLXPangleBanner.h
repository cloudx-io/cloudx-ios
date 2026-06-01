//
//  CLXPangleBanner.h
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
 * Pangle banner adapter.
 *
 * Manages the lifecycle of Pangle banner/MREC ads including loading, showing,
 * and cleanup.
 */
@interface CLXPangleBanner : CLXAdapterBanner <PAGBannerAdDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, assign, readonly) CLXBannerType bannerType;
@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type;

@end

NS_ASSUME_NONNULL_END
