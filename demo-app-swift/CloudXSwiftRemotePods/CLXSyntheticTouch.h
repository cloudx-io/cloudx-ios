@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 * Generates synthetic UITouch events for in-app ad interaction testing.
 *
 * WHY PRIVATE APIS: There is no public UIKit API to programmatically inject
 * touch events into a running app. XCTest's UI testing uses an out-of-process
 * accessibility service that cannot be embedded in-app. The alternative —
 * external click tools like cliclick — requires the simulator window to be
 * visible and frontmost, preventing parallel agent execution on different sims.
 *
 * This class uses UIKit private APIs (valueForKey:@"_touchesEvent",
 * _setLocationInWindow:, _addTouch:forDelayedDelivery:) via objc_msgSend.
 * These are NOT KVC on objects we own — they are the mechanism by which we
 * access UIKit's internal touch delivery system. There is no public equivalent.
 *
 * SCOPE: Demo/test apps only. Never ship in production SDK code.
 *
 * WHY TWO METHODS: Ad SDKs use different click-tracking architectures.
 * - tapAtPoint:onView:inWindow: targets a SPECIFIC view (e.g., the hitTest result,
 *   which is the ad SDK's click-tracking overlay). Best for click testing.
 * - tapAtPoint:inWindow: bypasses overlays to find the deepest WebKit view.
 *   Best for dismiss testing where we need to reach close buttons inside WKWebViews.
 */
@interface CLXSyntheticTouch : NSObject

/// Synthesizes a UITouch began/ended sequence targeting a specific view.
/// @param windowPoint Touch location in window coordinates.
/// @param targetView The view to receive the touch (determines which gesture recognizers fire).
/// @param window The key window.
/// @return YES if the touch was successfully dispatched.
+ (BOOL)tapAtPoint:(CGPoint)windowPoint onView:(UIView *)targetView inWindow:(UIWindow *)window;

/// Finds the deepest WebKit view at the point and dispatches a synthetic tap on it.
/// Falls back to hitTest: if no WebKit view is found. Used for dismiss testing
/// where ad SDK overlays must be bypassed to reach WKWebView close buttons.
/// @return YES if the touch was successfully dispatched.
+ (BOOL)tapAtPoint:(CGPoint)windowPoint inWindow:(UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
