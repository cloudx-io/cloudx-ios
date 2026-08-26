//
//  CloudXGAMInterstitialAdapter.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GAM custom event adapter for CloudX prebid interstitials.
 *
 * Dashboard-facing class name: publishers register it on their CloudX
 * interstitial line item.
 */
@interface CloudXGAMInterstitialAdapter : NSObject <GADMediationAdapter>
@end

NS_ASSUME_NONNULL_END
