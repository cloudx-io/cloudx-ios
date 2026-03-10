//
//  CLXUnityBannerFactory.m
//  CloudXUnityAdapter
//

#if __has_include(<CloudXUnityAdapter/CLXUnityBannerFactory.h>)
#import <CloudXUnityAdapter/CLXUnityBannerFactory.h>
#else
#import "CLXUnityBannerFactory.h"
#endif

#if __has_include(<CloudXUnityAdapter/CLXUnityBanner.h>)
#import <CloudXUnityAdapter/CLXUnityBanner.h>
#else
#import "CLXUnityBanner.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXUnityBannerFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityBannerFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityBannerFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXUnityBannerFactory alloc] init];
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

    CLXUnityBanner *banner = [[CLXUnityBanner alloc] initWithBidPayload:adm
                                                            placementID:placementID
                                                          placementName:adUnitName
                                                                  bidID:bidId
                                                                   type:type
                                                               delegate:delegate];
    return banner;
}

@end
