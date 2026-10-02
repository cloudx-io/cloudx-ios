#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Demo host for a CloudX-first interstitial with a lazy AdMob fallback. DemoSdkStartup brings up
 * both SDKs; once CloudX has answered (or after 15 s without an answer) this screen builds a
 * FirstLookInterstitialController, retries failed loads and shows with a capped backoff and
 * reports each step in the status lines.
 */
@interface FirstLookViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
