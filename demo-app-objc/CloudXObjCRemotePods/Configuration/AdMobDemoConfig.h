#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The AdMob IDs the First Look and Arbiter/TPA flows load. They are Google's test IDs: replace them,
 * and the GADApplicationIdentifier in Info.plist, with your own IDs before using either flow in a
 * production app.
 */
@interface AdMobDemoConfig : NSObject

/** Google's test interstitial for iOS. `-DemoApp.AdMobInterstitialAdUnitId <id>` overrides it for one launch. */
@property (class, nonatomic, copy, readonly) NSString *interstitialAdUnitId;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
