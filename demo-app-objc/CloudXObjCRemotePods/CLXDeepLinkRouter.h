#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Routes deep link URLs to the appropriate ad format tab and triggers load/show actions.
 *
 * @discussion Handles the `cloudx-demo://` URL scheme. Used by automated test runners
 * to exercise all ad formats via `xcrun simctl openurl` or `xcrun simctl launch` with arguments.
 *
 * Supported routes:
 *   cloudx-demo://init[?env=production|staging|dev]
 *   cloudx-demo://test?format=<FORMAT>[&action=load|show]
 *   cloudx-demo://test-all
 *
 * Launch arguments (preferred for automation — avoids iOS URL scheme confirmation dialog):
 *   -CLXTestFormat <banner|mrec|interstitial|rewarded> [-CLXTestAction <load|show>]
 *   -CLXTestCommand <init|test-all>
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
 * Reads `-CLXTestFormat`, `-CLXTestAction`, and `-CLXTestCommand` from NSProcessInfo.arguments,
 * constructs the corresponding deep link URL, and dispatches it after a short delay.
 */
+ (void)handleLaunchArguments;

@end

NS_ASSUME_NONNULL_END
