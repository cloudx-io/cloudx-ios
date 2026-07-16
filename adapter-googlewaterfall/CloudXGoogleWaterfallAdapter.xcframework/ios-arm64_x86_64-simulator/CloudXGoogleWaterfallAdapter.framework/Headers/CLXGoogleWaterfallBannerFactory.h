#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallBannerFactory : CLXAdapterBannerFactory

- (nullable CLXAdapterBanner *)createWithType:(CLXBannerType)type
                                         adId:(NSString *)adId
                                        bidId:(NSString *)bidId
                                          adm:(NSString *)adm
                              hasClosedButton:(BOOL)hasClosedButton
                                       extras:(NSDictionary<NSString *, NSString *> *)extras
                                   adUnitName:(nullable NSString *)adUnitName;

@end

NS_ASSUME_NONNULL_END
