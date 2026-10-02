#import <UIKit/UIKit.h>

@class AdDemoTabViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 * Demo-only launch screen that picks which demo flow to enter. It makes no SDK calls.
 * General opens the CloudX integration demo (AdDemoTabViewController). First Look
 * (FirstLookViewController) demonstrates a CloudX-first interstitial with an AdMob fallback.
 * Arbiter/TPA (ArbiterViewController) loads CloudX and AdMob in parallel and lets Trusted Arbiter
 * pick the interstitial to show.
 *
 * The screen is replaced as the window's root once a flow is picked, so it only shows again
 * when the app starts from scratch.
 */
@interface OptionsViewController : UIViewController

/**
 * Opens the General demo in the window, replacing whatever is shown there. Returns the new root
 * so callers can drive it right away: its tabs are already built.
 */
+ (AdDemoTabViewController *)openGeneralInWindow:(UIWindow *)window;

/** Opens the First Look demo in the window, replacing whatever is shown there. */
+ (void)openFirstLookInWindow:(UIWindow *)window;

/** Opens the Arbiter/TPA demo in the window, replacing whatever is shown there. */
+ (void)openArbiterInWindow:(UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
