#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Exponential backoff for AdMob prefetch failures. Mirrors Android BackoffPolicy:
/// 10s base, doubles each retry (exponent clamped at 20), capped at 5 minutes.
/// The throttle delay (GMA's own throttler engaged) is the cap.
@interface CLXGoogleWaterfallBackoffPolicy : NSObject

/// Delay in seconds for a given zero-based retry count.
+ (NSTimeInterval)nextDelayForRetryCount:(NSInteger)retryCount;

/// Long delay used when GMA signals its throttler is engaged (invalid-request).
+ (NSTimeInterval)throttleDelay;

@end

NS_ASSUME_NONNULL_END
