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
                                                     adId:(NSString *)adId
                                              placementId:(NSString *)placementId
                                               bidPayload:(nullable NSString *)bidPayload
                                                    bidID:(NSString *)bidID
                                               bannerSize:(CGSize)bannerSize
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    [self.baseFactory.logger debug:[NSString stringWithFormat:@"Creating banner - AdID: %@, Placement: %@, Size: %.0fx%.0f", 
                                    adId, placementId, bannerSize.width, bannerSize.height]];
    
    long long inmobiPlacementID = [self.baseFactory extractPlacementID:placementId];
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID"];
        return nil;
    }
    
    NSData *bidPayloadData = nil;
    if (bidPayload && bidPayload.length > 0) {
        bidPayloadData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    CLXInMobiBanner *banner = [[CLXInMobiBanner alloc] initWithBidPayload:bidPayloadData
                                                               placementID:inmobiPlacementID
                                                                     bidID:bidID
                                                                      size:bannerSize
                                                            viewController:viewController
                                                                  delegate:delegate];
    
    [self.baseFactory.logger debug:@"Banner adapter created successfully"];
    
    return banner;
}

@end

