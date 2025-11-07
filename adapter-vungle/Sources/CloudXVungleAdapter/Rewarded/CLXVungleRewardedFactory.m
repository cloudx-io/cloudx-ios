//
//  CLXVungleRewardedFactory.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleRewardedFactory.h"
#import "CLXVungleRewarded.h"
#import "CLXVungleBaseFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleRewardedFactory

#pragma mark - Class Methods

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"VungleRewardedFactory"];
    });
    return logger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

#pragma mark - CLXAdapterRewardedFactory Protocol

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                            bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                           extras:(NSDictionary<NSString *, NSString *> *)extras
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    CLXLogger *logger = [[self class] logger];
    
    // Validate required parameters
    if (!bidId || bidId.length == 0) {
        [logger error:@"Cannot create rewarded adapter - bidId is nil or empty"];
        return nil;
    }
    
    if (!delegate) {
        [logger error:@"Cannot create rewarded adapter - delegate is nil"];
        return nil;
    }
    
    // Validate Vungle SDK initialization
    if (![CLXVungleBaseFactory validateVungleInitialization:logger]) {
        return nil;
    }
    
    // Resolve placement ID from extras or fallback to adId
    NSString *placementId = [CLXVungleBaseFactory resolveVunglePlacementID:extras
                                                                fallbackAdId:adId
                                                                      logger:logger];
    
    // Validate the resolved placement ID
    if (!placementId || placementId.length == 0) {
        [logger error:@"Cannot create rewarded adapter - no valid placement ID (checked extras and adId)"];
        return nil;
    }
    
    // Extract bid payload from ADM if present
    NSString *bidPayload = [CLXVungleBaseFactory extractBidPayloadFromADM:adm logger:logger];
    
    // Create user info for logging
    NSDictionary *userInfo = [CLXVungleBaseFactory createAdapterUserInfo:adId
                                                                    bidId:bidId
                                                              placementId:placementId
                                                                   extras:extras];
    
    [logger info:[NSString stringWithFormat:@"Creating Vungle rewarded adapter - Placement: %@, BidID: %@, HasBidPayload: %@",
                    placementId, bidId, bidPayload ? @"YES" : @"NO"]
           ];
    
    // Create and return the adapter
    CLXVungleRewarded *adapter = [[CLXVungleRewarded alloc] initWithBidPayload:bidPayload
                                                                   placementID:placementId
                                                                         bidID:bidId
                                                                      delegate:delegate];
    
    if (!adapter) {
        [logger error:@"Failed to create Vungle rewarded adapter" ];
        return nil;
    }
    
    [logger debug:@"Successfully created Vungle rewarded adapter" ];
    return adapter;
}

@end
