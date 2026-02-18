//
//  CLXVungleBannerFactory.m
//  CloudXVungleAdapter
//

#import "CLXVungleBannerFactory.h"
#import "CLXVungleBanner.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleBannerFactory

static CLXLogger *_bannerFactoryLogger = nil;

+ (CLXLogger *)logger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bannerFactoryLogger = [[CLXLogger alloc] initWithCategory:@"CLXVungleBannerFactory"];
    });
    return _bannerFactoryLogger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                     type:(CLXBannerType)type
                                                     adId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                          hasClosedButton:(BOOL)hasClosedButton
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                              adUnitName:(NSString *)adUnitName
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate {

    CLXLogger *logger = [[self class] logger];

    NSString *placementId = extras[@"placement_id"];

    [logger info:[NSString stringWithFormat:@"Creating Vungle banner adapter - Ad Unit: %@ (%@), BidID: %@, Type: %ld, HasBidPayload: %@",
                    adUnitName ?: @"(unknown)", placementId, bidId, (long)type, adm ? @"YES" : @"NO"]
           ];

    // ALWAYS create and return adapter (even with invalid parameters)
    // Validation errors will be reported in load() via delegate callback
    CLXVungleBanner *adapter = [[CLXVungleBanner alloc] initWithBidPayload:adm
                                                               placementID:placementId
                                                             adUnitName:adUnitName
                                                                     bidID:bidId
                                                                      type:type
                                                                  delegate:delegate];

    [logger debug:@"Successfully created Vungle banner adapter"];
    return adapter;
}

@end
