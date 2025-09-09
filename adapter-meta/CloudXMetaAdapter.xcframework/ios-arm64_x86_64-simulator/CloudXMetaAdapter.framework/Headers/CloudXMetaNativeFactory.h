//
//  CloudXMetaNativeFactory.h
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

@interface CloudXMetaNativeFactory : NSObject <CloudXAdapterNativeFactory>

+ (instancetype)createInstance;

- (nullable id<CloudXAdapterNative>)createWithViewController:(UIViewController *)viewController
                                                       type:(CloudXNativeTemplate)type
                                                       adId:(NSString *)adId
                                                      bidId:(NSString *)bidId
                                                        adm:(NSString *)adm
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                   delegate:(id<CloudXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 