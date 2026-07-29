//
//  CLXRevenuePrecision.h
//  CloudXCore
//
//  Precision of a publisher-reported impression revenue value.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Precision of the revenue reported in CLXRevenueData.
 *
 * Intentionally a class rather than an enum so future precision tokens can be added
 * without making the public API look like a closed set (mirrors CLXArbiterPrecision and
 * Android's CloudXRevenuePrecision). The [name] token is sent to CloudX services as-is;
 * precision is optional — when unset, it is omitted from the adRevenue payload.
 */
CLX_PUBLIC
@interface CLXRevenuePrecision : NSObject <NSCopying>

/**
 * Stable precision token sent to CloudX services (e.g. "exact").
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 * Exact, real-time auction value (bidding).
 */
@property (class, nonatomic, strong, readonly) CLXRevenuePrecision *exact NS_SWIFT_NAME(exact);

/**
 * Aggregated or estimated value (e.g. Auto-CPM).
 */
@property (class, nonatomic, strong, readonly) CLXRevenuePrecision *estimated NS_SWIFT_NAME(estimated);

/**
 * Value assigned by the publisher (waterfall).
 */
@property (class, nonatomic, strong, readonly) CLXRevenuePrecision *publisherDefined NS_SWIFT_NAME(publisherDefined);

/**
 * Not enough data to determine precision.
 */
@property (class, nonatomic, strong, readonly) CLXRevenuePrecision *undefined NS_SWIFT_NAME(undefined);

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
