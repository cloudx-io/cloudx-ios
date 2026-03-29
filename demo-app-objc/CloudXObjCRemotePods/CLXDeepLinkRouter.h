#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Routes deep link URLs and launch arguments to ad format tabs, triggering load/show actions.
 *
 * @discussion Handles the `cloudx-demo://` URL scheme. Used by automated test runners
 * to exercise all ad formats via `xcrun simctl launch` with arguments.
 *
 * Supported routes:
 *   cloudx-demo://init[?env=production|staging|dev|local]
 *   cloudx-demo://test?format=<FORMAT>[&action=load|show|load-show]
 *   cloudx-demo://test-all[?env=staging]
 *
 * Launch arguments (preferred — avoids iOS URL scheme confirmation dialog):
 *   -CLXTestCommand test-all [-CLXTestEnv staging]
 *   -CLXTestFormat <banner|mrec|interstitial|rewarded|rewarded-interstitial> [-CLXTestAction <load|show|load-show>]
 *
 * test-all flow:
 *   1. Triggers SDK init with the specified environment (default: staging)
 *   2. Waits for SDK init completion (cloudXSDKInitialized notification, 30s timeout)
 *   3. Loads each ad format, polling for completion (30s per format)
 *   4. Shows fullscreen ads (interstitial, rewarded, rewarded-interstitial) after load succeeds
 *   5. Dismisses any blocking alerts automatically
 *   6. Logs structured results for each format
 */
@interface CLXDeepLinkRouter : NSObject

/**
 * @brief Attempts to handle a deep link URL.
 * @param url The URL to handle.
 * @return YES if the URL was recognized and handled, NO otherwise.
 */
+ (BOOL)handleURL:(NSURL *)url;

/**
 * @brief Checks process launch arguments for test commands and dispatches them.
 *
 * @discussion Call from `application:didFinishLaunchingWithOptions:` after the UI is set up.
 * Reads `-CLXTestFormat`, `-CLXTestAction`, `-CLXTestCommand`, and `-CLXTestEnv`
 * from NSProcessInfo.arguments, constructs the corresponding deep link URL, and dispatches.
 */
+ (void)handleLaunchArguments;

@end

NS_ASSUME_NONNULL_END
