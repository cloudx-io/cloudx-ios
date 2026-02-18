//
//  CLXVungleInterstitialFactory.m
//  CloudXVungleAdapter
//

#import "CLXVungleInterstitialFactory.h"
#import "CLXVungleInterstitial.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleInterstitialFactory

static CLXLogger *_interstitialFactoryLogger = nil;

+ (CLXLogger *)logger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _interstitialFactoryLogger = [[CLXLogger alloc] initWithCategory:@"CLXVungleInterstitialFactory"];
    });
    return _interstitialFactoryLogger;
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

    [logger info:[NSString stringWithFormat:@"Creating Vungle interstitial adapter - Ad Unit: %@ (%@), BidID: %@, HasBidPayload: %@",
                    adUnitName ?: @"(unknown)", placementId, bidId, adm ? @"YES" : @"NO"]
           ];

    // ALWAYS create and return adapter
    CLXVungleInterstitial *adapter = [[CLXVungleInterstitial alloc] initWithBidPayload:adm
                                                                           placementID:placementId  // May be nil
                                                                         adUnitName:adUnitName  // For error messages
                                                                                 bidID:bidId
                                                                              delegate:delegate];

    [logger debug:@"Successfully created Vungle interstitial adapter" ];
    return adapter;
}

@end
