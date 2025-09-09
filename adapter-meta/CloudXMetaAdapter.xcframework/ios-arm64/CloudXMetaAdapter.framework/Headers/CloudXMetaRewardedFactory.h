//
//  CloudXMetaRewardedFactory.h
//  CloudXMetaAdapter
//
//  Created by CloudX on 2024-02-14.
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CloudXMetaRewardedFactory : NSObject <CloudXAdapterRewardedFactory>

+ (instancetype)createInstance;

- (nullable id<CloudXAdapterRewarded>)createWithAdId:(NSString *)adId
                                              bidId:(NSString *)bidId
                                                adm:(NSString *)adm
                                             extras:(NSDictionary<NSString *, NSString *> *)extras
                                           delegate:(id<CloudXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 