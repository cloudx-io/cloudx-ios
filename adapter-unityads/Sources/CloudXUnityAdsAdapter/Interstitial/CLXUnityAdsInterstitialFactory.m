//
//  CLXUnityAdsInterstitialFactory.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsInterstitialFactory.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsInterstitialFactory.h>
#else
#import "CLXUnityAdsInterstitialFactory.h"
#endif

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsInterstitial.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsInterstitial.h>
#else
#import "CLXUnityAdsInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXUnityAdsInterstitialFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityAdsInterstitialFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsInterstitialFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXUnityAdsInterstitialFactory alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                           adUnitName:(nullable NSString *)adUnitName
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial for placement: %@ (%@)", adUnitName ?: @"(unknown)", adId]];

    NSString *placementID = extras[@"placement_id"];
    if (!placementID || placementID.length == 0) {
        placementID = adId;
        [self.logger debug:[NSString stringWithFormat:@"No placement_id in extras, using fallback: %@", adId]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Using placement ID from extras: %@", placementID]];
    }

    CLXUnityAdsInterstitial *interstitial = [[CLXUnityAdsInterstitial alloc] initWithBidPayload:adm
                                                                              placementID:placementID
                                                                            placementName:adUnitName
                                                                                    bidID:bidId
                                                                                 delegate:delegate];
    return interstitial;
}

@end
