//
//  CLXMolocoRewardedFactory.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoRewardedFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoRewardedFactory.h>
#else
#import "CLXMolocoRewardedFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoRewarded.h>)
#import <CloudXMolocoAdapter/CLXMolocoRewarded.h>
#else
#import "CLXMolocoRewarded.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBaseFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBaseFactory.h>
#else
#import "../Base/CLXMolocoBaseFactory.h"
#endif

#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXMolocoRewardedFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMolocoRewardedFactory

+ (instancetype)createInstance {
    return [[CLXMolocoRewardedFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoRewardedFactory"];
    }
    return self;
}

- (NSString *)network {
    return @"moloco";
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                       bidPayload:(nullable NSString *)bidPayload
                                            bidID:(NSString *)bidID
                                     adapterExtras:(nullable NSDictionary<NSString *, NSString *> *)adapterExtras
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded ad - AdId: %@", adId]];
    
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
    CLXMolocoRewarded *rewarded = 
        [[CLXMolocoRewarded alloc] initWithBidPayload:bidPayload
                                          placementID:placementID  // May be nil
                                                bidID:bidID
                                             delegate:delegate];
    
    return rewarded;
}

@end

