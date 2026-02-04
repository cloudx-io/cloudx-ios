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
        logger = [[CLXLogger alloc] initWithCategory:@"VungleBannerFactory"];
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
                                              adUnitName:(NSString *)adUnitName
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    CLXLogger *logger = [[self class] logger];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    
    // Log warnings for missing parameters (validation deferred to load())
    if (!viewController) {
        [logger error:@"viewController is nil - validation will be deferred to load()"];
    }
    
    if (!bidId || bidId.length == 0) {
        [logger error:@"bidId is nil or empty - validation will be deferred to load()"];
    }
    
    if (!delegate) {
        [logger error:@"delegate is nil - validation will be deferred to load()"];
    }
    
    // Validate banner type support (log warning only)
    if (![self isBannerTypeSupported:type]) {
        [logger error:[NSString stringWithFormat:@"Unsupported banner type: %ld - validation will be deferred to load()", (long)type]];
    }
    
    // Vungle SDK initialization check (log warning only)
    if (![CLXVungleBaseFactory validateVungleInitialization:logger]) {
        [logger error:@"Vungle SDK not initialized - validation will be deferred to load()"];
    }
    
    // Resolve placement ID from extras or fallback to adId
    NSString *placementId = [CLXVungleBaseFactory resolveVunglePlacementID:extras
                                                               fallbackAdId:adId
                                                                     logger:logger];
    
    // Log warning if placement ID is invalid (validation deferred to load())
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
    
    [logger info:[NSString stringWithFormat:@"Creating Vungle banner adapter - Ad Unit: %@ (%@), BidID: %@, Type: %ld, HasBidPayload: %@",
                    adUnitName ?: @"(unknown)", placementId, bidId, (long)type, bidPayload ? @"YES" : @"NO"]
           ];
    
    // Log close button parameter (note: Vungle banners don't typically support close buttons)
    if (hasClosedButton) {
        [logger debug:@"Close button requested - Vungle banners handle this automatically" ];
    }
    
    // ALWAYS create and return adapter (even with invalid parameters)
    // Validation errors will be reported in load() via delegate callback
    CLXVungleBanner *adapter = [[CLXVungleBanner alloc] initWithBidPayload:bidPayload
                                                               placementID:placementId  // May be nil
                                                             adUnitName:adUnitName  // For error messages
                                                                     bidID:bidId
                                                                      type:type
                                                            viewController:viewController  // May be nil
                                                                  delegate:delegate];  // May be nil
    
    [logger debug:@"Successfully created Vungle banner adapter"];
    return adapter;
}

#pragma mark - Private Methods

- (BOOL)isBannerTypeSupported:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeW320H50:  // 320x50 (or 728x90 on iPad)
        case CLXBannerTypeMREC:     // 300x250
            return YES;
            
        default:
            return NO;
    }
}

@end
