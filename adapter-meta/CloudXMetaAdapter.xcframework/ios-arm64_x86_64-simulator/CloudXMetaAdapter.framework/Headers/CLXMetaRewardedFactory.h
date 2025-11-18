//
//  CLXMetaRewardedFactory.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CloudXCore.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaRewardedFactory : NSObject <CLXAdapterRewardedFactory>

+ (CLXLogger *)logger;
+ (instancetype)createInstance;

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                               bidId:(NSString *)bidId
                                                 adm:(NSString *)adm
                                              extras:(NSDictionary<NSString *, NSString *> *)extras
                                            delegate:(id<CLXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 