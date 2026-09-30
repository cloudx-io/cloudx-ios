#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Brings up both SDKs for a demo flow that loads CloudX and AdMob side by side. Google Mobile Ads
 * starts right away. CloudX initializes after the App Tracking Transparency answer, so its first
 * requests carry that answer.
 *
 * `onStatus` receives the combined "CloudX: … | AdMob: …" line whenever either part changes.
 * `onCloudXSettled` is called once: YES when CloudX initialized, NO when it failed or did not
 * answer within 15 s. An answer after the timeout only updates the status line.
 */
@interface DemoSdkStartup : NSObject

- (instancetype)initWithStatusHandler:(void (^)(NSString *status))onStatus
                 cloudXSettledHandler:(void (^)(BOOL cloudXAvailable))onCloudXSettled NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)start;

@end

NS_ASSUME_NONNULL_END
