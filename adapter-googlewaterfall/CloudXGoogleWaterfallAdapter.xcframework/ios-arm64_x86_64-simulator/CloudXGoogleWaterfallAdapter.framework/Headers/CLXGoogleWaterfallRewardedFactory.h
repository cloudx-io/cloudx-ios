#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallRewardedFactory : CLXAdapterRewardedFactory

- (nullable CLXAdapterRewarded *)createWithAdId:(NSString *)adId
                                          bidId:(NSString *)bidId
                                            adm:(NSString *)adm
                                         extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(nullable NSString *)adUnitName;

@end

NS_ASSUME_NONNULL_END
