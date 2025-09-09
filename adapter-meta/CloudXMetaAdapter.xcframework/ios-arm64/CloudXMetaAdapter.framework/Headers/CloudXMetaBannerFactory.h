//
//  CloudXMetaBannerFactory.h
//  CloudXMetaAdapter
//
//  Created by CloudX on 2024-02-14.
//

#import <Foundation/Foundation.h>

// Conditional import for Swift bridging header.
// This allows the adapter to work with CocoaPods (where CloudXCore-Swift.h is generated),
// but not with Swift Package Manager (SPM), which does not generate this header.
#if __has_include(<CloudXCore/CloudXCore-Swift.h>)
#import <CloudXCore/CloudXCore-Swift.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CloudXMetaBannerFactory : NSObject <CloudXAdapterBannerFactory>

+ (instancetype)createInstance;

- (nullable id<CloudXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                        type:(CloudXBannerType)type
                                                        adId:(NSString *)adId
                                                       bidId:(NSString *)bidId
                                                         adm:(NSString *)adm
                                             hasClosedButton:(BOOL)hasClosedButton
                                                      extras:(NSDictionary<NSString *, NSString *> *)extras
                                                    delegate:(id<CloudXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 