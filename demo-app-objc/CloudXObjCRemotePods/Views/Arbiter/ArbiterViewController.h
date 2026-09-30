#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Demo host for the Trusted Arbiter interstitial. DemoSdkStartup brings up both SDKs; this screen
 * builds an ArbiterInterstitialController, turns its events into status lines and retries with a
 * capped backoff when neither platform fills or a show fails. Every load, show, arbiter and revenue
 * call lives in the controller.
 */
@interface ArbiterViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
