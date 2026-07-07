//
//  CLXMobileFuseBidderSignalsProvider.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides the MobileFuse bidding token for OpenRTB auction requests.
 * The token round-trip is dispatched onto a background queue because the
 * underlying token-provider call can block while acquiring an internal lock.
 *
 * @discussion The completion handler supplied via the inherited
 *   `-provideBidderSignalsWithParams:` (`params.completion`) runs on a MobileFuse
 *   SDK-owned worker thread, not on the main queue. Callers that touch UIKit
 *   or main-thread-only state inside the completion must re-dispatch to the
 *   main queue.
 */
@interface CLXMobileFuseBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
