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

/**
 * A manual price for every Arbiter/TPA AdMob bid, in USD per impression, or nil for none.
 * `-DemoApp.AdMobManualRevenuePerImpressionUSD <usd>` sets it for one launch so QA can run a round
 * that compares prices: Google's test unit reports 0, so without it the AdMob bid never has a
 * price. A testing aid only; leave it unset in a production app.
 */
@property (class, nonatomic, strong, readonly, nullable) NSNumber *manualRevenuePerImpressionUSD;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
