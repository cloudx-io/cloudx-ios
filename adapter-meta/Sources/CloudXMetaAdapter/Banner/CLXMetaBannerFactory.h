//
//  CLXMetaBannerFactory.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>

// Conditional import for CloudXCore header.
// This allows the adapter to work with both SPM and CocoaPods.
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaBannerFactory : NSObject <CLXAdapterBannerFactory>

+ (CLXLogger *)logger;
+ (instancetype)createInstance;

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                         type:(CLXBannerType)type
                                                         adId:(NSString *)adId
                                                        bidId:(NSString *)bidId
                                                          adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                       extras:(NSDictionary<NSString *, NSString *> *)extras
                                                     delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 