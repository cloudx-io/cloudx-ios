//
//  CLXPangleAdView.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Pangle banner adapter.
 *
 * Manages the lifecycle of Pangle banner/MREC ads including loading and cleanup.
 */
@interface CLXPangleAdView : CLXAdapterAdView <PAGBannerAdDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, assign, readonly) CLXBannerType bannerType;
@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                              type:(CLXBannerType)type
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
