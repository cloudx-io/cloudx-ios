//
//  CLXUnityAdsRewardedFactory.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsRewardedFactory.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsRewardedFactory.h>
#else
#import "CLXUnityAdsRewardedFactory.h"
#endif

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsRewarded.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsRewarded.h>
#else
#import "CLXUnityAdsRewarded.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXUnityAdsRewardedFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityAdsRewardedFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsRewardedFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXUnityAdsRewardedFactory alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                            bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                           extras:(NSDictionary<NSString *, NSString *> *)extras
                                       adUnitName:(nullable NSString *)adUnitName
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded for placement: %@ (%@)", adUnitName ?: @"(unknown)", adId]];

    NSString *placementID = extras[@"placement_id"];
    if (!placementID || placementID.length == 0) {
        placementID = adId;
        [self.logger debug:[NSString stringWithFormat:@"No placement_id in extras, using fallback: %@", adId]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Using placement ID from extras: %@", placementID]];
    }

    CLXUnityAdsRewarded *rewarded = [[CLXUnityAdsRewarded alloc] initWithBidPayload:adm
                                                                  placementID:placementID
                                                                placementName:adUnitName
                                                                        bidID:bidId
                                                                     delegate:delegate];
    return rewarded;
}

@end
