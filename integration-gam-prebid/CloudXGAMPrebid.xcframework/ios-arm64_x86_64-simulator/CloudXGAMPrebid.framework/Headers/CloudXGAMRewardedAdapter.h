//
//  CloudXGAMRewardedAdapter.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GAM custom event adapter for CloudX prebid rewarded ads.
 *
 * Dashboard-facing class name: publishers register it on their CloudX rewarded
 * line item.
 */
@interface CloudXGAMRewardedAdapter : NSObject <GADMediationAdapter>
@end

NS_ASSUME_NONNULL_END
