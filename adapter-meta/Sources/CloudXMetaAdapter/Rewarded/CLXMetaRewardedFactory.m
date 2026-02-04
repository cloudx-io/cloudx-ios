//
//  CLXMetaRewardedFactory.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaRewardedFactory.h>)
#import <CloudXMetaAdapter/CLXMetaRewardedFactory.h>
#else
#import "CLXMetaRewardedFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaRewarded.h>)
#import <CloudXMetaAdapter/CLXMetaRewarded.h>
#else
#import "CLXMetaRewarded.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaUtils.h>)
#import <CloudXMetaAdapter/CLXMetaUtils.h>
#else
#import "CLXMetaUtils.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaRewardedFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaRewardedFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaRewardedFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXMetaRewardedFactory alloc] init];
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                            bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                           extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(NSString *)adUnitName
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded for ad unit: %@ (%@)", adUnitName ?: @"(unknown)", adId]];

    NSString *metaPlacementID = [CLXMetaUtils resolveMetaPlacementID:extras
                                                         fallbackAdId:adId
                                                               logger:self.logger];

    if (!metaPlacementID || metaPlacementID.length == 0) {
        [self.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }

    CLXMetaRewarded *rewarded = [[CLXMetaRewarded alloc] initWithBidPayload:adm
                                                                placementID:metaPlacementID
                                                              adUnitName:adUnitName
                                                                      bidID:bidId
                                                                   delegate:delegate];

    return rewarded;
}

@end 
