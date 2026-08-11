#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "CLXGoogleWaterfallAdLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallAdViewLoader : NSObject <CLXGoogleWaterfallAdLoader, GADBannerViewDelegate>
- (instancetype)initWithBannerView:(GADBannerView *)bannerView
                   requestProvider:(CLXGoogleWaterfallRequestProvider)requestProvider
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
