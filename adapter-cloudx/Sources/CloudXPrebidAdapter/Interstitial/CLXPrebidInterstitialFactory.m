//
//  CLXPrebidInterstitialFactory.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 interstitial factory implementation
//

#import "CLXPrebidInterstitialFactory.h"
#import "CLXPrebidInterstitial.h"

@implementation CLXPrebidInterstitialFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                   bidId:(NSString *)bidId
                                                     adm:(NSString *)adm
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                 delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    return [[CLXPrebidInterstitial alloc] initWithAdm:adm
                                                  bidID:bidId
                                                delegate:delegate];
}

@end 