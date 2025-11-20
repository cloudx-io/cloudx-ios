//
//  CLXInMobiInterstitialFactory.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInterstitialFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiInterstitialFactory.h>
#else
#import "CLXInMobiInterstitialFactory.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInterstitial.h>)
#import <CloudXInMobiAdapter/CLXInMobiInterstitial.h>
#else
#import "CLXInMobiInterstitial.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBaseFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBaseFactory.h>
#else
#import "../Base/CLXInMobiBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXInMobiInterstitialFactory ()
@property (nonatomic, strong) CLXInMobiBaseFactory *baseFactory;
@end

@implementation CLXInMobiInterstitialFactory

+ (instancetype)createInstance {
    return [[CLXInMobiInterstitialFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseFactory = [[CLXInMobiBaseFactory alloc] init];
    }
    return self;
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {

    [self.baseFactory.logger debug:[NSString stringWithFormat:@"Creating interstitial - AdID: %@, BidID: %@",
                                    adId, bidId]];

    // Extract InMobi placement ID from extras
    NSString *placementId = extras[@"placement_id"];
    long long inmobiPlacementID = [self.baseFactory extractPlacementID:placementId];
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID"];
        return nil;
    }

    // Validate bid payload (adm)
    if (![self.baseFactory validateBidPayload:adm]) {
        [self.baseFactory.logger error:@"Invalid bid payload"];
        return nil;
    }

    // Convert bid payload string to NSData if present
    NSData *bidPayloadData = nil;
    if (adm && adm.length > 0) {
        bidPayloadData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    }

    // Create interstitial adapter
    CLXInMobiInterstitial *interstitial = [[CLXInMobiInterstitial alloc] initWithBidPayload:bidPayloadData
                                                                                 placementID:inmobiPlacementID
                                                                                       bidID:bidId
                                                                                    delegate:delegate];

    [self.baseFactory.logger debug:@"Interstitial adapter created successfully"];

    return interstitial;
}

@end

