#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXArbiterPlatform.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Result of an arbiter.
 */
CLX_PUBLIC
@interface CLXArbiterResult : NSObject

/**
 * Locally unique identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 * Platform selected by the arbiter.
 */
@property (nonatomic, strong, readonly) CLXArbiterPlatform *platform;

/**
 * Identifier of the bid selected by the arbiter, or nil when platform is NONE.
 */
@property (nonatomic, copy, readonly, nullable) NSString *bidId;

/**
 * Arbiter-provided metadata for the selected bid.
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *extras;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
