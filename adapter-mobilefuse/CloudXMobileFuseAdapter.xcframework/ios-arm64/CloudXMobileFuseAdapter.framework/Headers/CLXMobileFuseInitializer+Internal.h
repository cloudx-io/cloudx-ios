//
//  CLXMobileFuseInitializer+Internal.h
//  CloudXMobileFuseAdapter
//

#if __has_include(<CloudXMobileFuseAdapter/CLXMobileFuseInitializer.h>)
#import <CloudXMobileFuseAdapter/CLXMobileFuseInitializer.h>
#else
#import "CLXMobileFuseInitializer.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * The MobileFuse network SDK version this adapter is built and tested against.
 * Format: MAJOR.MINOR.PATCH (e.g., "1.11.0").
 * Reported as the network SDK version when the live value has not been resolved yet.
 */
FOUNDATION_EXPORT NSString * const CLXMobileFuseExpectedNetworkSDKVersion;

@interface CLXMobileFuseInitializer (Internal)

/**
 * Resolves the MobileFuse network SDK version string, caches it for @c sdkVersion, and
 * returns it.
 *
 * May block: when called off the main thread with no cached value, this hops to the main
 * queue. Call it only from a context that can afford that.
 */
+ (NSString *)primeSDKVersion;

#if defined(DEBUG) || defined(TESTING)
// Exposes the version cache so a test can prove it is observing an unprimed read: the linked
// SDK reports the same version as the pin, so the returned value alone cannot prove it.
+ (nullable NSString *)__cachedSDKVersionForTesting;
#endif

@end

NS_ASSUME_NONNULL_END
