#import <UIKit/UIKit.h>
#import "FirstLookInterstitialController.h"

NS_ASSUME_NONNULL_BEGIN

/** The lazy AdMob fallback. A loaded ad can be shown once and expires after one hour. */
@interface AdMobFirstLookSource : NSObject <FirstLookInterstitialSource>

- (instancetype)initWithViewController:(UIViewController *)viewController adUnitId:(NSString *)adUnitId NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
