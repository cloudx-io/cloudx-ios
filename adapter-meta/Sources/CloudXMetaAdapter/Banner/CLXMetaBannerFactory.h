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

@interface CLXMetaBannerFactory : NSObject <CLXAdapterBannerFactory>

+ (instancetype)createInstance;

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                         type:(CLXBannerType)type
                                                         adId:(NSString *)adId
                                                        bidId:(NSString *)bidId
                                                          adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                       extras:(NSDictionary<NSString *, NSString *> *)extras
                                                placementName:(NSString *)placementName
                                                     delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 