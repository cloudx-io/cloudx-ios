//
//  CloudXGAMKeyValues.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Key-values the publisher attaches to their GAM request as custom targeting.
 *
 * `cx_bid_id` is the single-use prebid token; `cx_price` is the price bucket
 * the CloudX line items target.
 */
@interface CloudXGAMKeyValues : NSObject

/** @brief Single-use prebid token (`cx_bid_id`). */
@property (nonatomic, copy, readonly) NSString *bidId;
/** @brief Price bucket keyword (`cx_price`). */
@property (nonatomic, copy, readonly) NSString *price;

- (instancetype)initWithBidId:(NSString *)bidId price:(NSString *)price NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/** @brief Custom-targeting dictionary: `cx_bid_id` and `cx_price`. */
- (NSDictionary<NSString *, NSString *> *)asDictionary;

@end

NS_ASSUME_NONNULL_END
