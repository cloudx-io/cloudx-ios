//
//  CloudXGAMBannerAdapter.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GAM custom event adapter for CloudX prebid banners/MRECs.
 *
 * The class name is dashboard-facing: publishers register it as the custom
 * event class on their CloudX banner line item. GAM instantiates it, hands it
 * the line item's server parameter (the CloudX bid token), and this adapter
 * consumes the matching registration and renders the cached CloudX view.
 */
@interface CloudXGAMBannerAdapter : NSObject <GADMediationAdapter>
@end

NS_ASSUME_NONNULL_END
