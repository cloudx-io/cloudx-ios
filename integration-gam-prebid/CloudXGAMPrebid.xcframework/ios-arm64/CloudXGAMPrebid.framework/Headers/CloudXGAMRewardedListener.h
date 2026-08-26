//
//  CloudXGAMRewardedListener.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import "CloudXGAMAdListener.h"

@class CLXAd;
@class CLXReward;

NS_ASSUME_NONNULL_BEGIN

/**
 * Publisher callbacks for the GAM prebid rewarded facade.
 *
 * Extends `CloudXGAMAdListener` with the reward grant. `onAdReady:` still
 * delivers the key-values for the next GAM request; the display lifecycle and
 * reward fan out from the CloudX creative shown via the GAM custom event.
 */
@protocol CloudXGAMRewardedListener <CloudXGAMAdListener>

/** @brief User earned the reward from the CloudX rewarded creative. */
- (void)onUserRewarded:(CLXAd *)ad reward:(CLXReward *)reward;

@end

NS_ASSUME_NONNULL_END
