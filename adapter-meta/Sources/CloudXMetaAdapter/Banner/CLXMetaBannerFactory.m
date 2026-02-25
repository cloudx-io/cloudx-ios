//
//  CLXMetaBannerFactory.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaBannerFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBannerFactory.h>
#else
#import "CLXMetaBannerFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaUtils.h>)
#import <CloudXMetaAdapter/CLXMetaUtils.h>
#else
#import "CLXMetaUtils.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBanner.h>)
#import <CloudXMetaAdapter/CLXMetaBanner.h>
#else
#import "CLXMetaBanner.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaBannerFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaBannerFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBannerFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXMetaBannerFactory alloc] init];
}

- (nullable id<CLXAdapterBanner>)createWithType:(CLXBannerType)type
                                                     adId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                          hasClosedButton:(BOOL)hasClosedButton
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                              adUnitName:(NSString *)adUnitName
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating banner for ad unit: %@ (%@)", adUnitName ?: @"(unknown)", adId]];

    NSString *metaPlacementID = [CLXMetaUtils resolveMetaPlacementID:extras
                                                         fallbackAdId:adId
                                                               logger:self.logger];

    if (!metaPlacementID || metaPlacementID.length == 0) {
        [self.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }

    CLXMetaBanner *banner = [[CLXMetaBanner alloc] initWithBidPayload:adm
                                                          placementID:metaPlacementID
                                                        adUnitName:adUnitName
                                                                bidID:bidId
                                                                 type:type
                                                             delegate:delegate];

    return banner;
}

@end 
