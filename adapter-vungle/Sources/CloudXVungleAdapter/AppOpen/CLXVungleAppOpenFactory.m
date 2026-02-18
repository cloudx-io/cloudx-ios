//
//  CLXVungleAppOpenFactory.m
//  CloudXVungleAdapter
//

#import "CLXVungleAppOpenFactory.h"
#import "CLXVungleInterstitial.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleAppOpenFactory

static CLXLogger *_appOpenFactoryLogger = nil;

+ (CLXLogger *)logger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _appOpenFactoryLogger = [[CLXLogger alloc] initWithCategory:@"CLXVungleAppOpenFactory"];
    });
    return _appOpenFactoryLogger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                         adUnitName:(NSString *)adUnitName
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {

    CLXLogger *logger = [[self class] logger];

    NSString *placementId = extras[@"placement_id"];

    [logger info:[NSString stringWithFormat:@"Creating Vungle app open adapter - Ad Unit: %@ (%@), BidID: %@, HasBidPayload: %@",
                    adUnitName ?: @"(unknown)", placementId, bidId, adm ? @"YES" : @"NO"]];

    return [[CLXVungleInterstitial alloc] initWithBidPayload:adm
                                               placementID:placementId
                                                adUnitName:adUnitName
                                                     bidID:bidId
                                                  delegate:delegate];
}

@end
