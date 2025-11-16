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
                                       delegate:(id<CLXAdapterBannerDelegate>)delegate
                                         adSize:(CLXBannerAdSize)adSize {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating banner - AdId: %@, Size: %dx%d", 
                       adId, (int)adSize.width, (int)adSize.height]];
    
    NSString *placementID = [CLXMolocoBaseFactory resolveMolocoPlacementID:adapterExtras 
                                                               fallbackAdId:adId 
                                                                     logger:self.logger];
    
    if (!placementID || placementID.length == 0) {
        [self.logger error:@"Invalid placement ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithBanner:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid placement ID"];
            [delegate didFailToLoadWithBanner:nil error:error];
        }
        return nil;
    }
    
    CLXMolocoBanner *banner = 
        [[CLXMolocoBanner alloc] initWithBidPayload:bidPayload
                                        placementID:placementID
                                              bidID:bidID
                                           delegate:delegate
                                             adSize:adSize];
    
    return banner;
}

@end

