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
                                     adUnitName:(NSString *)adUnitName
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
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
    NSString *placementId = [CLXVungleBaseFactory resolveVunglePlacementID:extras
                                                               fallbackAdId:adId
                                                                     logger:logger];
    
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
    
    [logger info:[NSString stringWithFormat:@"Creating Vungle rewarded adapter - Ad Unit: %@ (%@), BidID: %@, HasBidPayload: %@",
                    adUnitName ?: @"(unknown)", placementId, bidId, bidPayload ? @"YES" : @"NO"]
           ];
    
    // ALWAYS create and return adapter
    CLXVungleRewarded *adapter = [[CLXVungleRewarded alloc] initWithBidPayload:bidPayload
                                                                   placementID:placementId  // May be nil
                                                                 adUnitName:adUnitName  // For error messages
                                                                         bidID:bidId
                                                                      delegate:delegate];  // May be nil
    
    if (!adapter) {
        [logger error:@"Failed to create Vungle rewarded adapter" ];
        return nil;
    }
    
    [logger debug:@"Successfully created Vungle rewarded adapter" ];
    return adapter;
}

@end
