//
//  CLXVungleRewardedFactory.m
//  CloudXVungleAdapter
//

#import "CLXVungleRewardedFactory.h"
#import "CLXVungleRewarded.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleRewardedFactory

static CLXLogger *_rewardedFactoryLogger = nil;

+ (CLXLogger *)logger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _rewardedFactoryLogger = [[CLXLogger alloc] initWithCategory:@"CLXVungleRewardedFactory"];
    });
    return _rewardedFactoryLogger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                            bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                           extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(NSString *)adUnitName
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {

    CLXLogger *logger = [[self class] logger];

    NSString *placementId = extras[@"placement_id"];

    [logger info:[NSString stringWithFormat:@"Creating Vungle rewarded adapter - Ad Unit: %@ (%@), BidID: %@, HasBidPayload: %@",
                    adUnitName ?: @"(unknown)", placementId, bidId, adm ? @"YES" : @"NO"]
           ];

    // ALWAYS create and return adapter
    CLXVungleRewarded *adapter = [[CLXVungleRewarded alloc] initWithBidPayload:adm
                                                                   placementID:placementId  // May be nil
                                                                 adUnitName:adUnitName  // For error messages
                                                                         bidID:bidId
                                                                      delegate:delegate];  // May be nil

    [logger debug:@"Successfully created Vungle rewarded adapter" ];
    return adapter;
}

@end
