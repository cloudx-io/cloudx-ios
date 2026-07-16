#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallBanner : CLXAdapterBanner <GADBannerViewDelegate, CLXDestroyable>

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                       type:(CLXBannerType)type;

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                       type:(CLXBannerType)type
           fallbackGraceSec:(NSTimeInterval)fallbackGraceSec NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
