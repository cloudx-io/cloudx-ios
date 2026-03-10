//
//  CLXUnityRewardedFactory.m
//  CloudXUnityAdapter
//

#if __has_include(<CloudXUnityAdapter/CLXUnityRewardedFactory.h>)
#import <CloudXUnityAdapter/CLXUnityRewardedFactory.h>
#else
#import "CLXUnityRewardedFactory.h"
#endif

#if __has_include(<CloudXUnityAdapter/CLXUnityRewarded.h>)
#import <CloudXUnityAdapter/CLXUnityRewarded.h>
#else
#import "CLXUnityRewarded.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXUnityRewardedFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityRewardedFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityRewardedFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXUnityRewardedFactory alloc] init];
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

    CLXUnityRewarded *rewarded = [[CLXUnityRewarded alloc] initWithBidPayload:adm
                                                                  placementID:placementID
                                                                placementName:adUnitName
                                                                        bidID:bidId
                                                                     delegate:delegate];
    return rewarded;
}

@end
