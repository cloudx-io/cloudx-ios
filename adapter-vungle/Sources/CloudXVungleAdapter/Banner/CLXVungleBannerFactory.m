//
//  CLXVungleBannerFactory.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleBannerFactory.h"
#import "CLXVungleBanner.h"
#import "CLXVungleBaseFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@implementation CLXVungleBannerFactory

#pragma mark - Class Methods

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [CLXLogger loggerWithTag:@"VungleBannerFactory"];
    });
    return logger;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

#pragma mark - CLXAdapterBannerFactory Protocol

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                     type:(CLXBannerType)type
                                                     adId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                          hasClosedButton:(BOOL)hasClosedButton
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    CLXLogger *logger = [[self class] logger];
    
    // Validate required parameters
    if (!viewController) {
        [logger logError:@"Cannot create banner adapter - viewController is nil"];
        return nil;
    }
    
    if (!adId || adId.length == 0) {
        [logger logError:@"Cannot create banner adapter - adId is nil or empty"];
        return nil;
    }
    
    if (!bidId || bidId.length == 0) {
        [logger logError:@"Cannot create banner adapter - bidId is nil or empty"];
        return nil;
    }
    
    if (!delegate) {
        [logger logError:@"Cannot create banner adapter - delegate is nil"];
        return nil;
    }
    
    // Validate banner type support
    if (![self isBannerTypeSupported:type]) {
        [logger logError:[NSString stringWithFormat:@"Unsupported banner type: %ld", (long)type]];
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
    
    [logger logInfo:[NSString stringWithFormat:@"Creating Vungle banner adapter - Placement: %@, BidID: %@, Type: %ld, HasBidPayload: %@",
                    placementId, bidId, (long)type, bidPayload ? @"YES" : @"NO"]
           userInfo:userInfo];
    
    // Log close button parameter (note: Vungle banners don't typically support close buttons)
    if (hasClosedButton) {
        [logger logDebug:@"Close button requested - Vungle banners handle this automatically" userInfo:userInfo];
    }
    
    // Create and return the adapter
    CLXVungleBanner *adapter = [[CLXVungleBanner alloc] initWithBidPayload:bidPayload
                                                               placementID:placementId
                                                                     bidID:bidId
                                                                      type:type
                                                            viewController:viewController
                                                                  delegate:delegate];
    
    if (!adapter) {
        [logger logError:@"Failed to create Vungle banner adapter" userInfo:userInfo];
        return nil;
    }
    
    [logger logDebug:@"Successfully created Vungle banner adapter" userInfo:userInfo];
    return adapter;
}

#pragma mark - Private Methods

- (BOOL)isBannerTypeSupported:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeBanner:           // 320x50
        case CLXBannerTypeMediumRectangle:  // 300x250 (MREC)
        case CLXBannerTypeLeaderboard:      // 728x90
            return YES;
            
        default:
            return NO;
    }
}

@end
