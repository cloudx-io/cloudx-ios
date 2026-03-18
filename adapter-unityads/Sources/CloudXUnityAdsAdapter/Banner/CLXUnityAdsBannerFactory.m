//
//  CLXUnityAdsBannerFactory.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsBannerFactory.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsBannerFactory.h>
#else
#import "CLXUnityAdsBannerFactory.h"
#endif

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsBanner.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsBanner.h>
#else
#import "CLXUnityAdsBanner.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXUnityAdsBannerFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityAdsBannerFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsBannerFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXUnityAdsBannerFactory alloc] init];
}

- (nullable id<CLXAdapterBanner>)createWithType:(CLXBannerType)type
                                                       adId:(NSString *)adId
                                                      bidId:(NSString *)bidId
                                                        adm:(NSString *)adm
                                            hasClosedButton:(BOOL)hasClosedButton
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                 adUnitName:(nullable NSString *)adUnitName
                                                   delegate:(id<CLXAdapterBannerDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating banner for placement: %@ (%@)", adUnitName ?: @"(unknown)", adId]];

    NSString *placementID = extras[@"placement_id"];
    if (!placementID || placementID.length == 0) {
        placementID = adId;
        [self.logger debug:[NSString stringWithFormat:@"No placement_id in extras, using fallback: %@", adId]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Using placement ID from extras: %@", placementID]];
    }

    CLXUnityAdsBanner *banner = [[CLXUnityAdsBanner alloc] initWithBidPayload:adm
                                                            placementID:placementID
                                                          placementName:adUnitName
                                                                  bidID:bidId
                                                                   type:type
                                                               delegate:delegate];
    return banner;
}

@end
