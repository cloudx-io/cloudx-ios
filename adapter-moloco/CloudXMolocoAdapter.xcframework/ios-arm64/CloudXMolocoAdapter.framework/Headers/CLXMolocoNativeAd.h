//
//  CLXMolocoNativeAd.h
//  CloudXMolocoAdapter
//

#import <CloudXCore/CLXNativeAd.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudX native ad wrapper around a MolocoSDK MolocoNativeAd.
 * Bridges Moloco's asset model into CloudX's CLXNativeAd surface.
 */
@interface CLXMolocoNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) id<MolocoNativeAd> molocoNativeAd;

- (instancetype)initWithMolocoNativeAd:(id<MolocoNativeAd>)molocoNativeAd
                                assets:(id<MolocoNativeAdAssests>)assets;

@end

NS_ASSUME_NONNULL_END
