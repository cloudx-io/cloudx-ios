//
//  CLXMetaBannerFactory.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaBannerFactory : CLXAdapterBannerFactory

- (nullable CLXAdapterBanner *)createWithType:(CLXBannerType)type
                                                         adId:(NSString *)adId
                                                        bidId:(NSString *)bidId
                                                          adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                       extras:(NSDictionary<NSString *, NSString *> *)extras
                                                   adUnitName:(NSString *)adUnitName;

@end

NS_ASSUME_NONNULL_END 