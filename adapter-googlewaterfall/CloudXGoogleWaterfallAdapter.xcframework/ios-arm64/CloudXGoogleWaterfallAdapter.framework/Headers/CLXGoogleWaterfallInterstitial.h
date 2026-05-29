#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/// googleWaterfall supports banner + MREC only. This adapter exists so the
/// fullscreen factory surface matches sibling adapters and the reflective
/// resolver finds a class, but it fails closed: load/show report
/// @c CLXErrorCodeAdapterInvalidConfiguration and @c isReady is always NO. The
/// SSP never routes a fullscreen bid to this bidder.
@interface CLXGoogleWaterfallInterstitial : CLXAdapterInterstitial
@end

NS_ASSUME_NONNULL_END
