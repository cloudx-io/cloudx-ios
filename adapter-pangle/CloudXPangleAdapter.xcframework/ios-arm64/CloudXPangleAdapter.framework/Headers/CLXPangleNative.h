//
//  CLXPangleNative.h
//  CloudXPangleAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/// Pangle native ad adapter (loader). Loads a `PAGLNativeAd` and delivers a
/// `CLXPangleNativeAd` to the CloudX native pipeline (standalone native or, via
/// `CLXNativeBannerBridge`, native-in-banner / native-in-MREC).
@interface CLXPangleNative : CLXAdapterNative

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
