//
//  CLXPrebidRewardedFactory.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 rewarded factory implementation
//

#import "CLXPrebidRewardedFactory.h"
#import "CLXPrebidRewarded.h"

@implementation CLXPrebidRewardedFactory

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                               bidId:(NSString *)bidId
                                                 adm:(NSString *)adm
                                              extras:(NSDictionary<NSString *, NSString *> *)extras
                                            delegate:(id<CLXAdapterRewardedDelegate>)delegate {
        return [[CLXPrebidRewarded alloc] initWithAdm:adm
                                             bidID:bidId
                                           delegate:delegate];
}

@end 