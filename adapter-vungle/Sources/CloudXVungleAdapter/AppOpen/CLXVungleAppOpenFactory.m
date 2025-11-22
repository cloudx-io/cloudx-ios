//
//  CLXVungleAppOpenFactory.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleAppOpenFactory.h"
#import "CLXVungleAppOpen.h"
#import "CLXVungleBaseFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleAppOpenFactory

#pragma mark - Class Methods

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"VungleAppOpenFactory"];
    });
    return logger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

#pragma mark - CLXAdapterInterstitialFactory Protocol

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    CLXLogger *logger = [[self class] logger];
    
    // v1.3.0: No longer return nil - validation deferred to load()
    if (!bidId || bidId.length == 0) {
        [logger error:@"bidId is nil or empty - validation will be deferred to load()"];
    }
    
    if (!delegate) {
        [logger error:@"delegate is nil - validation will be deferred to load()"];
    }
    
    if (![CLXVungleBaseFactory validateVungleInitialization:logger]) {
        [logger error:@"Vungle SDK not initialized - validation will be deferred to load()"];
    }
    
    // Resolve placement ID from extras or fallback to adId
    NSString *placementId = [self resolveAppOpenPlacementID:extras fallbackAdId:adId logger:logger];
    
    if (!placementId || placementId.length == 0) {
        [logger error:@"No valid placement ID - validation will be deferred to load()"];
    }
    
    // Extract bid payload from ADM if present
    NSString *bidPayload = [CLXVungleBaseFactory extractBidPayloadFromADM:adm logger:logger];
    
    // Create user info for logging
    NSDictionary *userInfo = [CLXVungleBaseFactory createAdapterUserInfo:adId
                                                                    bidId:bidId
                                                              placementId:placementId
                                                                   extras:extras];
    
    [logger info:[NSString stringWithFormat:@"Creating Vungle App Open adapter - Placement: %@, BidID: %@, HasBidPayload: %@",
                    placementId, bidId, bidPayload ? @"YES" : @"NO"]];
    
    // ALWAYS create and return adapter
    CLXVungleAppOpen *adapter = [[CLXVungleAppOpen alloc] initWithBidPayload:bidPayload
                                                                 placementID:placementId  // May be nil
                                                                       bidID:bidId
                                                                    delegate:delegate];
    
    if (!adapter) {
        [logger error:@"Failed to create Vungle App Open adapter"];
        return nil;
    }
    
    [logger debug:@"Successfully created Vungle App Open adapter"];
    return adapter;
}

#pragma mark - Private Methods

- (NSString *)resolveAppOpenPlacementID:(NSDictionary<NSString *, NSString *> *)extras 
                             fallbackAdId:(NSString *)adId 
                                   logger:(CLXLogger *)logger {
    
    // Priority order for App Open placement ID resolution:
    // 1. vungle_appopen_placement_id from extras (most specific)
    // 2. appopen_placement_id from extras
    // 3. vungle_placement_id from extras
    // 4. placement_id from extras  
    // 5. adId as fallback
    
    NSString *placementId = extras[@"vungle_appopen_placement_id"];
    if (placementId && placementId.length > 0) {
        [logger debug:[NSString stringWithFormat:@"Using Vungle App Open placement ID from extras: %@", placementId]];
        return placementId;
    }
    
    placementId = extras[@"appopen_placement_id"];
    if (placementId && placementId.length > 0) {
        [logger debug:[NSString stringWithFormat:@"Using App Open placement ID from extras: %@", placementId]];
        return placementId;
    }
    
    // Fall back to standard Vungle placement resolution
    placementId = [CLXVungleBaseFactory resolveVunglePlacementID:extras fallbackAdId:adId logger:logger];
    [logger debug:[NSString stringWithFormat:@"Using standard placement ID for App Open: %@", placementId]];
    
    return placementId;
}

@end
