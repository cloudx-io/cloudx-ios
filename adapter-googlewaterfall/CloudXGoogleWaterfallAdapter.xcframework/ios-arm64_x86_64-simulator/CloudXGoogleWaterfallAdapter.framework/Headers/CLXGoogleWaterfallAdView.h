#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallAdView : CLXAdapterAdView <GADBannerViewDelegate, CLXDestroyable>

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                       type:(CLXBannerType)type
                     logger:(id<CLXAdapterLogger>)logger;

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                       type:(CLXBannerType)type
           fallbackGraceSec:(NSTimeInterval)fallbackGraceSec
                     logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
