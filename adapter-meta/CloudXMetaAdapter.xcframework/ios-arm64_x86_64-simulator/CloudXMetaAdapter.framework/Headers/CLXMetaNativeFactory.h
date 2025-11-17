//
//  CLXMetaNativeFactory.h
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

@interface CLXMetaNativeFactory : NSObject <CLXAdapterNativeFactory>

+ (CLXLogger *)logger;
+ (instancetype)createInstance;

- (nullable id<CLXAdapterNative>)createWithViewController:(UIViewController *)viewController
                                                        type:(CLXNativeTemplate)type
                                                        adId:(NSString *)adId
                                                       bidId:(NSString *)bidId
                                                         adm:(NSString *)adm
                                                      extras:(NSDictionary<NSString *, NSString *> *)extras
                                                    delegate:(id<CLXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 