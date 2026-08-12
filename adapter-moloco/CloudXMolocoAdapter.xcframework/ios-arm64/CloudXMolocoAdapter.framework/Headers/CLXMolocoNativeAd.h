//
//  CLXMolocoNativeAd.h
//  CloudXMolocoAdapter
//

#import <CloudXCore/CLXNativeAd.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudX native ad wrapper around a MolocoSDK MolocoNativeAd.
 * Bridges Moloco's asset model into CloudX's CLXNativeAd surface.
 */
@interface CLXMolocoNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) id<MolocoNativeAd> molocoNativeAd;

- (instancetype)initWithMolocoNativeAd:(id<MolocoNativeAd>)molocoNativeAd
                                assets:(id<MolocoNativeAdAssests>)assets
              handleImpressionInPrepare:(BOOL)handleImpressionInPrepare
                                logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
