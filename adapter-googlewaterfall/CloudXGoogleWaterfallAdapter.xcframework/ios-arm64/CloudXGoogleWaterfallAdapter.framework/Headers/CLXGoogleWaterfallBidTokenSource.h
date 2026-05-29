#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>

NS_ASSUME_NONNULL_BEGIN

/// Emits the prefetched fills snapshot as the googleWaterfall bidder signal.
/// Wire shape: `bidderSignals.googleWaterfall.fills` = stringified JSON array.
@interface CLXGoogleWaterfallBidTokenSource : CLXBidTokenSource
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
