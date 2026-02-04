//
//  CLXInMobiRewardedFactory.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiRewardedFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiRewardedFactory.h>
#else
#import "CLXInMobiRewardedFactory.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiRewarded.h>)
#import <CloudXInMobiAdapter/CLXInMobiRewarded.h>
#else
#import "CLXInMobiRewarded.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBaseFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBaseFactory.h>
#else
#import "../Base/CLXInMobiBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXInMobiRewardedFactory ()
@property (nonatomic, strong) CLXInMobiBaseFactory *baseFactory;
@end

@implementation CLXInMobiRewardedFactory

+ (instancetype)createInstance {
    return [[CLXInMobiRewardedFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseFactory = [[CLXInMobiBaseFactory alloc] init];
    }
    return self;
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                              bidId:(NSString *)bidId
                                                adm:(NSString *)adm
                                             extras:(NSDictionary<NSString *, NSString *> *)extras
                                       adUnitName:(NSString *)adUnitName
                                           delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    // Extract placement ID from extras (server provides this in adapter_extras)
    NSString *placementIdString = extras[@"placement_id"];
    [self.baseFactory.logger debug:[NSString stringWithFormat:@"Creating rewarded - Ad Unit: %@ (%@), BidID: %@, PlacementID: %@", adUnitName ?: @"(unknown)", adId, bidId, placementIdString]];
    
    long long inmobiPlacementID = [self.baseFactory extractPlacementID:placementIdString];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }
    
    NSData *bidPayloadData = nil;
    if (adm && adm.length > 0) {
        bidPayloadData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID = 0)
    // Validation errors will be reported in load() via delegate callback
    CLXInMobiRewarded *rewarded = [[CLXInMobiRewarded alloc] initWithBidPayload:bidPayloadData
                                                                     placementID:inmobiPlacementID  // May be 0 (invalid)
                                                                   adUnitName:adUnitName
                                                                           bidID:bidId
                                                                        delegate:delegate];
    
    [self.baseFactory.logger debug:@"Rewarded adapter created successfully"];
    
    return rewarded;
}

@end

