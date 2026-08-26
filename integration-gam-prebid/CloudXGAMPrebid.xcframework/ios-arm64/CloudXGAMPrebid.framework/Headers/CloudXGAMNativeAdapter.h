//
//  CloudXGAMNativeAdapter.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GAM custom event adapter for CloudX prebid native ads.
 *
 * Dashboard-facing class name: publishers register it on their CloudX native
 * line item.
 */
@interface CloudXGAMNativeAdapter : NSObject <GADMediationAdapter>
@end

NS_ASSUME_NONNULL_END
