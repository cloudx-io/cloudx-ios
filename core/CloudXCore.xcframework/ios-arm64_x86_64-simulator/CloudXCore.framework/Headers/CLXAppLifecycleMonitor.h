#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef id CLXLifecycleToken;

/// App-level lifecycle broadcast surface. Registers a single set of
/// UIApplication notification observers and re-broadcasts foreground/background
/// to block listeners. Pure broadcast — owns no policy. App-level only (no
/// scene granularity); MRAID handles scene transitions separately.
///
/// This is a long-lived singleton, so a listener block that strong-captures its
/// owner keeps that owner alive for the app's lifetime. Consumers must capture
/// weakly and call removeListener: on teardown.
@interface CLXAppLifecycleMonitor : NSObject

/// Block fires on UIApplicationWillEnterForegroundNotification, on whatever
/// thread posts it (main thread, as UIKit posts these notifications).
- (CLXLifecycleToken)addForegroundListener:(void (^)(void))block;

/// Block fires on UIApplicationDidEnterBackgroundNotification, on whatever
/// thread posts it (main thread, as UIKit posts these notifications).
- (CLXLifecycleToken)addBackgroundListener:(void (^)(void))block;

/// Stop delivering to the listener identified by token.
- (void)removeListener:(CLXLifecycleToken)token;

@end

NS_ASSUME_NONNULL_END
