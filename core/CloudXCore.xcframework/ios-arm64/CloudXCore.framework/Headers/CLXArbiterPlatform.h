#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Platform participating in an arbiter.
 *
 * This is intentionally a class instead of an enum so future platforms can be
 * added without making the public API look like a closed set.
 */
CLX_PUBLIC
@interface CLXArbiterPlatform : NSObject <NSCopying>

/**
 * Stable platform name sent to CloudX services.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 * CloudX arbiter input.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *cloudX NS_SWIFT_NAME(cloudX);

/**
 * LevelPlay arbiter input.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *levelPlay NS_SWIFT_NAME(levelPlay);

/**
 * PubMatic arbiter input.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *pubMatic NS_SWIFT_NAME(pubMatic);

/**
 * AdMob arbiter input.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *adMob NS_SWIFT_NAME(adMob);

/**
 * Google Ad Manager arbiter input.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *gam NS_SWIFT_NAME(gam);

/**
 * Custom arbiter input for a mediation platform not modeled by a dedicated factory.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *custom NS_SWIFT_NAME(custom);

/**
 * No bid candidates were supplied for the arbiter.
 */
@property (class, nonatomic, strong, readonly) CLXArbiterPlatform *none NS_SWIFT_NAME(none);

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
