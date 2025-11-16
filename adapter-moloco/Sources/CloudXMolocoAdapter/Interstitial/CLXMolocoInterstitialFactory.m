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
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial - AdId: %@, BidID: %@", adId, bidID]];
    
    // Resolve placement ID
    NSString *placementID = [CLXMolocoBaseFactory resolveMolocoPlacementID:adapterExtras 
                                                               fallbackAdId:adId 
                                                                     logger:self.logger];
    
    if (!placementID || placementID.length == 0) {
        [self.logger error:@"Invalid placement ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid placement ID"];
            [delegate didFailToLoadWithInterstitial:nil error:error];
        }
        return nil;
    }
    
    CLXMolocoInterstitial *interstitial = 
        [[CLXMolocoInterstitial alloc] initWithBidPayload:bidPayload
                                              placementID:placementID
                                                    bidID:bidID
                                                 delegate:delegate];
    
    return interstitial;
}

@end

