//
//  CLXMetaInterstitialFactory.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
// SPM requires angle brackets with module name, CocoaPods/Xcode supports quotes.
#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitialFactory.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitialFactory.h>
#else
#import "CLXMetaInterstitialFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitial.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitial.h>
#else
#import "CLXMetaInterstitial.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBaseFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBaseFactory.h>
#else
#import "CLXMetaBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaInterstitialFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaInterstitialFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaInterstitialFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    CLXMetaInterstitialFactory *instance = [[CLXMetaInterstitialFactory alloc] init];
    return instance;
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"✅ [CLXMetaInterstitialFactory] Creating interstitial for placement: %@ | bidPayload: %@", adId, adm ? @"YES" : @"NO"]];
    
    // Use shared base factory method to resolve Meta placement ID
    NSString *metaPlacementID = [CLXMetaBaseFactory resolveMetaPlacementID:extras 
                                                              fallbackAdId:adId 
                                                                    logger:self.logger];
    
    // Validate placement ID
    if (!metaPlacementID || metaPlacementID.length == 0) {
        [self.logger error:@"Cannot create interstitial adapter - placement ID is nil or empty"];
        return nil;
    }
    
    CLXMetaInterstitial *interstitial = [[CLXMetaInterstitial alloc] initWithBidPayload:adm
                                                                            placementID:metaPlacementID
                                                                                  bidID:bidId
                                                                               delegate:delegate];
    
    return interstitial;
}

@end 
