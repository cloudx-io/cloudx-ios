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

#import <CloudXCore/CLXLogger.h>

@interface CLXInMobiInterstitialFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXInMobiInterstitialFactory

+ (instancetype)createInstance {
    return [[CLXInMobiInterstitialFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInterstitialFactory"];
    }
    return self;
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                         adUnitName:(NSString *)adUnitName
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {

    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial - Ad Unit: %@ (%@), BidID: %@",
                         adUnitName ?: @"(unknown)", adId, bidId]];

    long long inmobiPlacementID = [extras[@"placement_id"] longLongValue];

    // Convert bid payload string to NSData if present
    NSData *bidPayloadData = nil;
    if (adm && adm.length > 0) {
        bidPayloadData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    }

    // ALWAYS create and return adapter (even with invalid placementID = 0)
    // Validation errors will be reported in load() via delegate callback
    CLXInMobiInterstitial *interstitial = [[CLXInMobiInterstitial alloc] initWithBidPayload:bidPayloadData
                                                                                 placementID:inmobiPlacementID  // May be 0 (invalid)
                                                                               adUnitName:adUnitName
                                                                                       bidID:bidId
                                                                                    delegate:delegate];

    return interstitial;
}

@end

