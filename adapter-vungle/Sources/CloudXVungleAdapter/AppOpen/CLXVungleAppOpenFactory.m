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
    
    // Validate required parameters
    if (!bidId || bidId.length == 0) {
        [logger error:@"Cannot create App Open adapter - bidId is nil or empty"];
        return nil;
    }
    
    if (!delegate) {
        [logger error:@"Cannot create App Open adapter - delegate is nil"];
        return nil;
    }
    
    // Validate Vungle SDK initialization
    if (![CLXVungleBaseFactory validateVungleInitialization:logger]) {
        return nil;
    }
    
    // Resolve placement ID from extras or fallback to adId
    NSString *placementId = [self resolveAppOpenPlacementID:extras fallbackAdId:adId logger:logger];
    
    // Validate the resolved placement ID
    if (!placementId || placementId.length == 0) {
        [logger error:@"Cannot create App Open adapter - no valid placement ID (checked extras and adId)"];
        return nil;
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
    
    // Create and return the adapter
    CLXVungleAppOpen *adapter = [[CLXVungleAppOpen alloc] initWithBidPayload:bidPayload
                                                                 placementID:placementId
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
