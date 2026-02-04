#import "CLXMintegralRewardedFactory.h"
#import "CLXMintegralRewarded.h"
#import "CLXMintegralIDExtractor.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXMintegralRewardedFactory

+ (instancetype)createInstance {
    return [[CLXMintegralRewardedFactory alloc] init];
}

- (NSString *)network {
    return @"mintegral";
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                            bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                           extras:(NSDictionary<NSString *, NSString *> *)extras
                                     adUnitName:(NSString *)adUnitName
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"[RewardedFactory] Creating - Ad Unit: %@ (%@), bidId:'%@'",
                        adUnitName ?: @"(unknown)", adId ?: @"(nil)", bidId ?: @"(nil)"]];
    
    // Extract IDs using shared utility
    CLXMintegralIDResult *ids = [CLXMintegralIDExtractor extractIDsFromExtras:extras
                                                                         adId:adId
                                                                   bidIdParam:bidId
                                                                       logger:self.logger];
    
    // Log validation warning if unitID is missing (validation deferred to load())
    if (!ids.unitID.length) {
        [self.logger error:@"[RewardedFactory] Missing unit_id - validation will be deferred to load()"];
    }
    
    // Use adm as bidPayload (nil-safe: messaging nil returns 0)
    NSString *bidPayload = adm.length > 0 ? adm : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"[RewardedFactory] Creating Mintegral rewarded - Ad Unit: %@, placementID:%@, unitID:%@, hasBidPayload:%@",
                        adUnitName ?: @"(unknown)", ids.placementID, ids.unitID, bidPayload ? @"YES" : @"NO"]];
    
    // Always create and return adapter (even with invalid parameters)
    // Validation errors will be reported in load() via delegate callback
    CLXMintegralRewarded *rewarded = [[CLXMintegralRewarded alloc] initWithBidPayload:bidPayload
                                                                          placementID:ids.placementID
                                                                        adUnitName:adUnitName
                                                                               unitID:ids.unitID
                                                                                bidID:ids.bidID ?: @""
                                                                             delegate:delegate];
    
    [self.logger debug:@"[RewardedFactory] Mintegral rewarded adapter created successfully"];
    return rewarded;
}

@end
