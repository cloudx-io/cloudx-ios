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
                                                     delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    [[CLXMetaBannerFactory logger] debug:[NSString stringWithFormat:@"✅ [CLXMetaBannerFactory] Creating banner for placement: %@ | bidPayload: %@", adId, adm ? @"YES" : @"NO"]];
    
    // Use shared base factory method to resolve Meta placement ID
    NSString *metaPlacementID = [CLXMetaBaseFactory resolveMetaPlacementID:extras 
                                                              fallbackAdId:adId 
                                                                    logger:[CLXMetaBannerFactory logger]];
    
    // Validate placement ID
    if (!metaPlacementID || metaPlacementID.length == 0) {
        [[CLXMetaBannerFactory logger] error:@"Cannot create banner adapter - placement ID is nil or empty"];
        return nil;
    }
    
    CLXMetaBanner *banner = [[CLXMetaBanner alloc] initWithBidPayload:adm
                                                           placementID:metaPlacementID
                                                                bidID:bidId
                                                                 type:type
                                                        viewController:viewController
                                                             delegate:delegate];
    
    return banner;
}

@end 
