#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoBidderSignalsProvider
 * @brief Supplies the BIGO Ads bidder token for each auction as the `bid_token` signal.
 * @discussion The token is read fresh from the partner SDK per auction and never cached
 *             across auctions. No signal is produced until the SDK is initialized.
 */
@interface CLXBigoBidderSignalsProvider : CLXAdapterBidderSignalsProvider

/**
 * @brief Shared provider instance; `+createInstance` returns the same object.
 * @return The singleton provider.
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
