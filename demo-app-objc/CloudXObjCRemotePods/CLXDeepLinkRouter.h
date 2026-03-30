#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief App-specific adapter that bridges the demo app to CLXTestHarnessEngine.
 *
 * @discussion Implements CLXTestHarnessApp to provide app-specific details
 * (tab navigation, format-to-selector mapping, ad state queries, logging).
 * All generic automation logic (dismiss detection, click testing, polling,
 * synthetic UITouch) lives in the CloudXTestHarness pod.
 *
 * Usage:
 *   In AppDelegate, after the window is set up:
 *     [CLXDeepLinkRouter setup];           // registers the adapter with the engine
 *     [CLXDeepLinkRouter handleLaunchArguments];  // dispatches launch-argument commands
 *
 *   For URL handling:
 *     [CLXDeepLinkRouter handleURL:url];
 */
@interface CLXDeepLinkRouter : NSObject

/// Register this adapter with the test harness engine.
/// Call once in application:didFinishLaunchingWithOptions:.
+ (void)setup;

/// Forward to CLXTestHarnessEngine handleURL:.
+ (BOOL)handleURL:(NSURL *)url;

/// Forward to CLXTestHarnessEngine handleLaunchArguments.
+ (void)handleLaunchArguments;

@end

NS_ASSUME_NONNULL_END
