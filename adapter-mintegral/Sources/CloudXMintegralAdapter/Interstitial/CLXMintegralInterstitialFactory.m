#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralInterstitial.h"
#import "CLXMintegralIDExtractor.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXMintegralInterstitialFactory

+ (instancetype)createInstance {
    return [[CLXMintegralInterstitialFactory alloc] init];
}

- (NSString *)network {
    return @"mintegral";
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"[InterstitialFactory] Creating - adId:'%@', bidId:'%@'",
                        adId ?: @"(nil)", bidId ?: @"(nil)"]];
    
    // Extract IDs using shared utility
    CLXMintegralIDResult *ids = [CLXMintegralIDExtractor extractIDsFromExtras:extras
                                                                         adId:adId
                                                                   bidIdParam:bidId
                                                                       logger:self.logger];
    
    // Log validation warning if unitID is missing (validation deferred to load())
    if (!ids.unitID.length) {
        [self.logger error:@"[InterstitialFactory] Missing unit_id - validation will be deferred to load()"];
    }
    
    // Use adm as bidPayload (nil-safe: messaging nil returns 0)
    NSString *bidPayload = adm.length > 0 ? adm : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"[InterstitialFactory] Creating Mintegral interstitial - placementID:%@, unitID:%@, hasBidPayload:%@",
                        ids.placementID, ids.unitID, bidPayload ? @"YES" : @"NO"]];
    
    // Always create and return adapter (even with invalid parameters)
    // Validation errors will be reported in load() via delegate callback
    CLXMintegralInterstitial *interstitial = [[CLXMintegralInterstitial alloc] initWithBidPayload:bidPayload
                                                                                      placementID:ids.placementID
                                                                                           unitID:ids.unitID
                                                                                            bidID:ids.bidID ?: @""
                                                                                         delegate:delegate];
    
    [self.logger debug:@"[InterstitialFactory] Mintegral interstitial adapter created successfully"];
    return interstitial;
}

@end
