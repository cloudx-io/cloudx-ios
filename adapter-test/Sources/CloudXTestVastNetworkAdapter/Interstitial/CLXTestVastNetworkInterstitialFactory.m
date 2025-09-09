//
//  CloudXTestVastNetworkInterstitialFactory.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import "CLXTestVastNetworkInterstitialFactory.h"
#import "CLXTestVastNetworkInterstitial.h"

@implementation CLXTestVastNetworkInterstitialFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                   bidId:(NSString *)bidId
                                                     adm:(NSString *)adm
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                 delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    return [[CLXTestVastNetworkInterstitial alloc] initWithAdm:adm
                                                            bidID:bidId
                                                          delegate:delegate];
}

@end 