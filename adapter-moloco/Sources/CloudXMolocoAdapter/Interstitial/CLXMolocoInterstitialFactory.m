//
//  CLXMolocoInterstitialFactory.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInterstitialFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoInterstitialFactory.h>
#else
#import "CLXMolocoInterstitialFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInterstitial.h>)
#import <CloudXMolocoAdapter/CLXMolocoInterstitial.h>
#else
#import "CLXMolocoInterstitial.h"
#endif

#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXMolocoInterstitialFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMolocoInterstitialFactory

+ (instancetype)createInstance {
    return [[CLXMolocoInterstitialFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoInterstitialFactory"];
    }
    return self;
}

- (NSString *)network {
    return @"moloco";
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                           bidPayload:(nullable NSString *)bidPayload
                                                bidID:(NSString *)bidID
                                          adapterExtras:(nullable NSDictionary<NSString *, NSString *> *)adapterExtras
                                        placementName:(nullable NSString *)placementName
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial - Placement: %@ (%@), BidID: %@", placementName ?: @"(unknown)", adId, bidID]];
    
    // Resolve placement ID
    NSString *placementID = [CLXMolocoBaseFactory resolveMolocoPlacementID:adapterExtras 
                                                               fallbackAdId:adId 
                                                                     logger:self.logger];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    if (!placementID || placementID.length == 0) {
        [self.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID)
    // Validation errors will be reported in load() via delegate callback
    CLXMolocoInterstitial *interstitial = 
        [[CLXMolocoInterstitial alloc] initWithBidPayload:bidPayload
                                              placementID:placementID  // May be nil
                                            placementName:placementName
                                                    bidID:bidID
                                                 delegate:delegate];
    
    return interstitial;
}

@end

