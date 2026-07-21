#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallInterstitial : CLXAdapterInterstitial

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
                     logger:(id<CLXAdapterLogger>)logger;

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
           fallbackGraceSec:(NSTimeInterval)fallbackGraceSec
                     logger:(id<CLXAdapterLogger>)logger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
