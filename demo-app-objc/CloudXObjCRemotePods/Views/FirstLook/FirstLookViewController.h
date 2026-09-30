#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Demo host for a CloudX-first interstitial with a lazy AdMob fallback. It starts Google Mobile
 * Ads, requests App Tracking Transparency and then initializes CloudX, builds a
 * FirstLookInterstitialController once CloudX has answered (or after 15 s without an answer),
 * retries failed loads and shows with a capped backoff and reports each step in the status lines.
 */
@interface FirstLookViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
