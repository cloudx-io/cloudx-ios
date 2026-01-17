//
//  CLXMetaBannerFactory.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
// SPM requires angle brackets with module name, CocoaPods/Xcode supports quotes.
#if __has_include(<CloudXMetaAdapter/CLXMetaBannerFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBannerFactory.h>
#else
#import "CLXMetaBannerFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBaseFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBaseFactory.h>
#else
#import "CLXMetaBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaBannerFactory ()
+ (CLXLogger *)logger;
@end

#if __has_include(<CloudXMetaAdapter/CLXMetaBanner.h>)
#import <CloudXMetaAdapter/CLXMetaBanner.h>
#else
#import "CLXMetaBanner.h"
#endif



@implementation CLXMetaBannerFactory

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBannerFactory"];
    });
    return logger;
}

+ (instancetype)createInstance {
    CLXMetaBannerFactory *instance = [[CLXMetaBannerFactory alloc] init];
    return instance;
}

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                         type:(CLXBannerType)type
                                                         adId:(NSString *)adId
                                                        bidId:(NSString *)bidId
                                                          adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                       extras:(NSDictionary<NSString *, NSString *> *)extras
                                                placementName:(NSString *)placementName
                                                     delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    [[CLXMetaBannerFactory logger] debug:[NSString stringWithFormat:@"Creating banner for placement: %@ (%@) | bidPayload: %@", placementName ?: @"(unknown)", adId, adm ? @"YES" : @"NO"]];
    
    // Use shared base factory method to resolve Meta placement ID
    NSString *metaPlacementID = [CLXMetaBaseFactory resolveMetaPlacementID:extras 
                                                              fallbackAdId:adId 
                                                                    logger:[CLXMetaBannerFactory logger]];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    if (!metaPlacementID || metaPlacementID.length == 0) {
        [[CLXMetaBannerFactory logger] error:@"Invalid placement ID - validation will be deferred to load()"];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID)
    // Validation errors will be reported in load() via delegate callback
    CLXMetaBanner *banner = [[CLXMetaBanner alloc] initWithBidPayload:adm
                                                           placementID:metaPlacementID  // May be nil
                                                         placementName:placementName  // For error messages
                                                                bidID:bidId
                                                                 type:type
                                                        viewController:viewController
                                                             delegate:delegate];
    
    return banner;
}

@end 
