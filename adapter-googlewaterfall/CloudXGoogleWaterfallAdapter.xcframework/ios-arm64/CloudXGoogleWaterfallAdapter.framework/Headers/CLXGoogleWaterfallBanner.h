#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/// Serves an already-prefetched AdMob banner/MREC. `-load` acquires the cached
/// GADBannerView from the prefetch worker (it does NOT issue a network load),
/// verifies the server-chosen ad unit, and installs serve-time listeners that
/// report impression + realized revenue (ILRD) to CloudX.
@interface CLXGoogleWaterfallBanner : CLXAdapterBanner <GADBannerViewDelegate, CLXDestroyable>

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                       type:(CLXBannerType)type;

/// Testing initializer: inject the ILRD fallback grace interval.
- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                       type:(CLXBannerType)type
           fallbackGraceSec:(NSTimeInterval)fallbackGraceSec NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
