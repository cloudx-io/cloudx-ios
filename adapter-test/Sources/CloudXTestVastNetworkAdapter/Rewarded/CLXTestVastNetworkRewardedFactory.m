//
//  CloudXTestVastNetworkRewardedFactory.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import "CLXTestVastNetworkRewardedFactory.h"
#import "CLXTestVastNetworkRewarded.h"

@implementation CLXTestVastNetworkRewardedFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                               bidId:(NSString *)bidId
                                                 adm:(NSString *)adm
                                              extras:(NSDictionary<NSString *, NSString *> *)extras
                                            delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    return [[CLXTestVastNetworkRewarded alloc] initWithAdm:adm
                                                        bidID:bidId
                                                     delegate:delegate];
}

@end 