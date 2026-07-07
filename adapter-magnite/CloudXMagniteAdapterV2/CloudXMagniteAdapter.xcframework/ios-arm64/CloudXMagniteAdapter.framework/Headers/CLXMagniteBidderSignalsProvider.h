//
//  CLXMagniteBidderSignalsProvider.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXMagniteBidderSignalsProvider
 * @brief Provides Magnite bidding tokens for server-side bid requests
 */
@interface CLXMagniteBidderSignalsProvider : CLXAdapterBidderSignalsProvider

+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
