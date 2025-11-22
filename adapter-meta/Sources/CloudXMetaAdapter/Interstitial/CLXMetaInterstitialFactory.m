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
    
    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial for placement: %@ | bidPayload: %@", adId, adm ? @"YES" : @"NO"]];
    
    // Use shared base factory method to resolve Meta placement ID
    NSString *metaPlacementID = [CLXMetaBaseFactory resolveMetaPlacementID:extras 
                                                              fallbackAdId:adId 
                                                                    logger:self.logger];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    if (!metaPlacementID || metaPlacementID.length == 0) {
        [self.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID)
    // Validation errors will be reported in load() via delegate callback
    CLXMetaInterstitial *interstitial = [[CLXMetaInterstitial alloc] initWithBidPayload:adm
                                                                            placementID:metaPlacementID  // May be nil
                                                                                  bidID:bidId
                                                                               delegate:delegate];
    
    return interstitial;
}

@end 
