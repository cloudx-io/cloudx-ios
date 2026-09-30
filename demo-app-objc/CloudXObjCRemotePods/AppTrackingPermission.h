#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** The App Tracking Transparency request, shared by the demo flows that load ads. */
@interface AppTrackingPermission : NSObject

/**
 * Asks for tracking authorization after a short delay, so the prompt lands on a screen that is
 * already visible, logs the answer and then calls `completion` on the main queue. When the
 * answer is already known iOS reports it without a prompt and `completion` still runs.
 */
+ (void)requestWithCompletion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
