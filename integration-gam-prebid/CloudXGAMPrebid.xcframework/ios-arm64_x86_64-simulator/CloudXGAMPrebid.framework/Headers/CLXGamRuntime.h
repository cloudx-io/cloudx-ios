//
//  CLXGamRuntime.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>

#import "CLXGamTokenRegistry.h"

@class CLXGamPriceBucketFormatter;

NS_ASSUME_NONNULL_BEGIN

/**
 * Module-wide shared state: the token registry (with the win-not-rendered TTL
 * backstop wired) and the price bucket formatter.
 *
 * @warning Integration-internal, NOT publisher API. This is exported only so the demo
 * harness can consume a token the way the custom event adapter does and simulate a GAM
 * dispatch without a live GAM account (Android's demo reaches the runtime the same way).
 * Publishers drive the integration through the CloudXGAM* facades; nothing here is
 * covered by the pod's API stability guarantees and it may change in any release.
 */
@interface CLXGamRuntime : NSObject

/** @brief Shared registry; TTL expiry emits the expired-shaped telemetry event. */
@property (class, nonatomic, readonly) CLXGamTokenRegistry *sharedRegistry;

/** @brief New formatter reflecting the applied `CloudXGAMConfig` bucket settings. */
+ (CLXGamPriceBucketFormatter *)bucketFormatter;

@end

NS_ASSUME_NONNULL_END
