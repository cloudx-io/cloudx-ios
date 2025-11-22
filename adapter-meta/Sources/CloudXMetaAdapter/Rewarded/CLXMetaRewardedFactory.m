//
//  CLXMetaRewardedFactory.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
// SPM requires angle brackets with module name, CocoaPods/Xcode supports quotes.
#if __has_include(<CloudXMetaAdapter/CLXMetaRewardedFactory.h>)
#import <CloudXMetaAdapter/CLXMetaRewardedFactory.h>
#else
#import "CLXMetaRewardedFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaRewarded.h>)
#import <CloudXMetaAdapter/CLXMetaRewarded.h>
#else
#import "CLXMetaRewarded.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBaseFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBaseFactory.h>
#else
#import "CLXMetaBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaRewardedFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaRewardedFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaRewardedFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    CLXMetaRewardedFactory *instance = [[CLXMetaRewardedFactory alloc] init];
    return instance;
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                               bidId:(NSString *)bidId
                                                 adm:(NSString *)adm
                                              extras:(NSDictionary<NSString *, NSString *> *)extras
                                            delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded for placement: %@ | bidPayload: %@", adId, adm ? @"YES" : @"NO"]];
    
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
    CLXMetaRewarded *rewarded = [[CLXMetaRewarded alloc] initWithBidPayload:adm
                                                                 placementID:metaPlacementID  // May be nil
                                                                      bidID:bidId
                                                                   delegate:delegate];
    
    return rewarded;
}

@end 
