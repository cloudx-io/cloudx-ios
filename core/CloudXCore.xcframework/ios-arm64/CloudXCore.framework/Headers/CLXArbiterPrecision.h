#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Revenue precision reported by a mediation platform for an arbiter bid.
 *
 * This is intentionally a class instead of an enum so future precision tokens
 * can be added without making the public API look like a closed set. Constants
 * mirror common mediator revenue precision values, upper-cased to match
 * CLXArbiterPlatform naming.
 */
CLX_PUBLIC
@interface CLXArbiterPrecision : NSObject <NSCopying>

/**
 * Stable precision token sent to CloudX services.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 * Price assigned by the publisher.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPrecision *publisherDefined NS_SWIFT_NAME(publisherDefined);

/**
 * Result of a real-time auction.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPrecision *exact NS_SWIFT_NAME(exact);

/**
 * Estimated revenue.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPrecision *estimated NS_SWIFT_NAME(estimated);

/**
 * Revenue amount unavailable or not enough data to estimate.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPrecision *undefined NS_SWIFT_NAME(undefined);

/**
 * Creates a precision from any token, normalized to upper case.
 */
+ (instancetype)precisionWithName:(NSString *)name NS_SWIFT_NAME(of(_:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
