//
//  CLXMolocoBannerFactory.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBannerFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBannerFactory.h>
#else
#import "CLXMolocoBannerFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBanner.h>)
#import <CloudXMolocoAdapter/CLXMolocoBanner.h>
#else
#import "CLXMolocoBanner.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBaseFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBaseFactory.h>
#else
#import "../Base/CLXMolocoBaseFactory.h"
#endif

#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXMolocoBannerFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMolocoBannerFactory

+ (instancetype)createInstance {
    return [[CLXMolocoBannerFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoBannerFactory"];
    }
    return self;
}

- (NSString *)network {
    return @"moloco";
}

- (nullable id<CLXAdapterBanner>)createWithAdId:(NSString *)adId
                                     bidPayload:(nullable NSString *)bidPayload
                                          bidID:(NSString *)bidID
                                   adapterExtras:(nullable NSDictionary<NSString *, NSString *> *)adapterExtras
                                  placementName:(nullable NSString *)placementName
                                        delegate:(id<CLXAdapterBannerDelegate>)delegate
                                          adSize:(CLXBannerAdSize)adSize {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating banner - Placement: %@ (%@), Size: %dx%d", 
                       placementName ?: @"(unknown)", adId, (int)adSize.width, (int)adSize.height]];
    
    NSString *placementID = [CLXMolocoBaseFactory resolveMolocoPlacementID:adapterExtras 
                                                               fallbackAdId:adId 
                                                                     logger:self.logger];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    // This aligns iOS behavior with Android
    if (!placementID || placementID.length == 0) {
        [self.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID)
    // Validation errors will be reported in load() via delegate callback
    CLXMolocoBanner *banner = 
        [[CLXMolocoBanner alloc] initWithBidPayload:bidPayload
                                        placementID:placementID  // May be nil
                                      placementName:placementName
                                              bidID:bidID
                                           delegate:delegate
                                             adSize:adSize];
    
    return banner;
}

@end

