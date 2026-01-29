//
//  CLXMetaInterstitialFactory.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitialFactory.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitialFactory.h>
#else
#import "CLXMetaInterstitialFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitial.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitial.h>
#else
#import "CLXMetaInterstitial.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaUtils.h>)
#import <CloudXMetaAdapter/CLXMetaUtils.h>
#else
#import "CLXMetaUtils.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaInterstitialFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaInterstitialFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaInterstitialFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXMetaInterstitialFactory alloc] init];
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                        placementName:(NSString *)placementName
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial for placement: %@ (%@)", placementName ?: @"(unknown)", adId]];

    NSString *metaPlacementID = [CLXMetaUtils resolveMetaPlacementID:extras
                                                         fallbackAdId:adId
                                                               logger:self.logger];

    if (!metaPlacementID || metaPlacementID.length == 0) {
        [self.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }

    CLXMetaInterstitial *interstitial = [[CLXMetaInterstitial alloc] initWithBidPayload:adm
                                                                            placementID:metaPlacementID
                                                                          placementName:placementName
                                                                                  bidID:bidId
                                                                               delegate:delegate];

    return interstitial;
}

@end 
