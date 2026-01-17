//
//  CLXInMobiBannerFactory.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBannerFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBannerFactory.h>
#else
#import "CLXInMobiBannerFactory.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBanner.h>)
#import <CloudXInMobiAdapter/CLXInMobiBanner.h>
#else
#import "CLXInMobiBanner.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBaseFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBaseFactory.h>
#else
#import "../Base/CLXInMobiBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBannerType.h>

@interface CLXInMobiBannerFactory ()
@property (nonatomic, strong) CLXInMobiBaseFactory *baseFactory;
@end

@implementation CLXInMobiBannerFactory

+ (instancetype)createInstance {
    return [[CLXInMobiBannerFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseFactory = [[CLXInMobiBaseFactory alloc] init];
    }
    return self;
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

    [self.baseFactory.logger debug:[NSString stringWithFormat:@"Creating banner - Placement: %@ (%@), BidID: %@, Type: %ld",
                                    placementName ?: @"(unknown)", adId, bidId, (long)type]];

    // Extract placement ID from extras
    NSString *placementId = extras[@"placement_id"];
    if (!placementId) {
        [self.baseFactory.logger error:@"Missing placement_id in extras"];
        return nil;
    }

    long long inmobiPlacementID = [self.baseFactory extractPlacementID:placementId];
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }

    // Convert banner type to size
    CGSize bannerSize;
    switch (type) {
        case CLXBannerTypeMREC:
            bannerSize = CGSizeMake(300, 250);
            break;
        case CLXBannerTypeW320H50:
        default:
            bannerSize = CGSizeMake(320, 50);
            break;
    }

    NSData *bidPayloadData = nil;
    if (adm && adm.length > 0) {
        bidPayloadData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    }

    // ALWAYS create and return adapter (even with invalid placementID = 0)
    // Validation errors will be reported in load() via delegate callback
    CLXInMobiBanner *banner = [[CLXInMobiBanner alloc] initWithBidPayload:bidPayloadData
                                                               placementID:inmobiPlacementID  // May be 0 (invalid)
                                                             placementName:placementName
                                                                     bidID:bidId
                                                                      size:bannerSize
                                                            viewController:viewController
                                                                  delegate:delegate];

    [self.baseFactory.logger debug:@"Banner adapter created successfully"];

    return banner;
}

@end

