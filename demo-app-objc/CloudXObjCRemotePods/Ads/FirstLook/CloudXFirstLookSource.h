#import <UIKit/UIKit.h>
#import "FirstLookInterstitialController.h"

NS_ASSUME_NONNULL_BEGIN

/** CloudX's leg of the First Look interstitial flow. */
@interface CloudXFirstLookSource : NSObject <FirstLookInterstitialSource>

/** Returns nil when the SDK cannot create the interstitial, for example when it is not initialized. */
- (nullable instancetype)initWithViewController:(UIViewController *)viewController adUnitId:(NSString *)adUnitId;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
