//
//  CLXVungleNativeFactory.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleNativeFactory.h"
#import "CLXVungleNative.h"
#import "CLXVungleBaseFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleNativeFactory

#pragma mark - Class Methods

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [CLXLogger loggerWithTag:@"VungleNativeFactory"];
    });
    return logger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

#pragma mark - CLXAdapterNativeFactory Protocol

- (nullable id<CLXAdapterNative>)createWithAdId:(NSString *)adId
                                          bidId:(NSString *)bidId
                                            adm:(NSString *)adm
                                         extras:(NSDictionary<NSString *, NSString *> *)extras
                                       delegate:(id<CLXAdapterNativeDelegate>)delegate {
    
    CLXLogger *logger = [[self class] logger];
    
    // Validate required parameters
    if (!adId || adId.length == 0) {
        [logger logError:@"Cannot create native adapter - adId is nil or empty"];
        return nil;
    }
    
    if (!bidId || bidId.length == 0) {
        [logger logError:@"Cannot create native adapter - bidId is nil or empty"];
        return nil;
    }
    
    if (!delegate) {
        [logger logError:@"Cannot create native adapter - delegate is nil"];
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
    
    [logger logInfo:[NSString stringWithFormat:@"Creating Vungle native adapter - Placement: %@, BidID: %@, HasBidPayload: %@",
                    placementId, bidId, bidPayload ? @"YES" : @"NO"]
           userInfo:userInfo];
    
    // Create and return the adapter
    CLXVungleNative *adapter = [[CLXVungleNative alloc] initWithBidPayload:bidPayload
                                                               placementID:placementId
                                                                     bidID:bidId
                                                                  delegate:delegate];
    
    if (!adapter) {
        [logger logError:@"Failed to create Vungle native adapter" userInfo:userInfo];
        return nil;
    }
    
    [logger logDebug:@"Successfully created Vungle native adapter" userInfo:userInfo];
    return adapter;
}

@end
