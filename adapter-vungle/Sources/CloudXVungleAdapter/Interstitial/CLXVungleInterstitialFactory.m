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
        logger = [CLXLogger loggerWithTag:@"VungleInterstitialFactory"];
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
    if (!adId || adId.length == 0) {
        [logger logError:@"Cannot create interstitial adapter - adId is nil or empty"];
        return nil;
    }
    
    if (!bidId || bidId.length == 0) {
        [logger logError:@"Cannot create interstitial adapter - bidId is nil or empty"];
        return nil;
    }
    
    if (!delegate) {
        [logger logError:@"Cannot create interstitial adapter - delegate is nil"];
        return nil;
    }
    
    // Validate Vungle SDK initialization
    if (![CLXVungleBaseFactory validateVungleInitialization:logger]) {
        return nil;
    }
    
    // Resolve placement ID
    NSString *placementId = [CLXVungleBaseFactory resolveVunglePlacementID:extras
                                                                fallbackAdId:adId
                                                                      logger:logger];
    
    // Extract bid payload from ADM if present
    NSString *bidPayload = [CLXVungleBaseFactory extractBidPayloadFromADM:adm logger:logger];
    
    // Create user info for logging
    NSDictionary *userInfo = [CLXVungleBaseFactory createAdapterUserInfo:adId
                                                                    bidId:bidId
                                                              placementId:placementId
                                                                   extras:extras];
    
    [logger logInfo:[NSString stringWithFormat:@"Creating Vungle interstitial adapter - Placement: %@, BidID: %@, HasBidPayload: %@",
                    placementId, bidId, bidPayload ? @"YES" : @"NO"]
           userInfo:userInfo];
    
    // Create and return the adapter
    CLXVungleInterstitial *adapter = [[CLXVungleInterstitial alloc] initWithBidPayload:bidPayload
                                                                           placementID:placementId
                                                                                 bidID:bidId
                                                                              delegate:delegate];
    
    if (!adapter) {
        [logger logError:@"Failed to create Vungle interstitial adapter" userInfo:userInfo];
        return nil;
    }
    
    [logger logDebug:@"Successfully created Vungle interstitial adapter" userInfo:userInfo];
    return adapter;
}

@end
