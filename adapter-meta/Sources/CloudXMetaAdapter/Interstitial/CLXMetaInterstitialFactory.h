//
//  CLXMetaInterstitialFactory.h
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

@interface CLXMetaInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

+ (CLXLogger *)logger;
+ (instancetype)createInstance;

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 