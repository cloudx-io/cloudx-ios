//
//  CLXUnityInterstitialFactory.m
//  CloudXUnityAdapter
//

#if __has_include(<CloudXUnityAdapter/CLXUnityInterstitialFactory.h>)
#import <CloudXUnityAdapter/CLXUnityInterstitialFactory.h>
#else
#import "CLXUnityInterstitialFactory.h"
#endif

#if __has_include(<CloudXUnityAdapter/CLXUnityInterstitial.h>)
#import <CloudXUnityAdapter/CLXUnityInterstitial.h>
#else
#import "CLXUnityInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXUnityInterstitialFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXUnityInterstitialFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityInterstitialFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXUnityInterstitialFactory alloc] init];
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

    CLXUnityInterstitial *interstitial = [[CLXUnityInterstitial alloc] initWithBidPayload:adm
                                                                              placementID:placementID
                                                                            placementName:adUnitName
                                                                                    bidID:bidId
                                                                                 delegate:delegate];
    return interstitial;
}

@end
