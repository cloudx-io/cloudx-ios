//
//  CLXVungleInterstitialFactory.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleInterstitialFactory.h"
#import "CLXVungleInterstitial.h"
#import "CLXVungleBaseFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleInterstitialFactory

#pragma mark - Class Methods

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"VungleInterstitialFactory"];
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
    
    [logger info:[NSString stringWithFormat:@"Creating Vungle interstitial adapter - Placement: %@, BidID: %@, HasBidPayload: %@",
                    placementId, bidId, bidPayload ? @"YES" : @"NO"]
           ];
    
    // ALWAYS create and return adapter
    CLXVungleInterstitial *adapter = [[CLXVungleInterstitial alloc] initWithBidPayload:bidPayload
                                                                           placementID:placementId  // May be nil
                                                                                 bidID:bidId
                                                                              delegate:delegate];
    
    if (!adapter) {
        [logger error:@"Failed to create Vungle interstitial adapter" ];
        return nil;
    }
    
    [logger debug:@"Successfully created Vungle interstitial adapter" ];
    return adapter;
}

@end
