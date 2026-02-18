//
//  CLXInMobiRewardedFactory.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiRewardedFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiRewardedFactory.h>
#else
#import "CLXInMobiRewardedFactory.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiRewarded.h>)
#import <CloudXInMobiAdapter/CLXInMobiRewarded.h>
#else
#import "CLXInMobiRewarded.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXInMobiRewardedFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXInMobiRewardedFactory

+ (instancetype)createInstance {
    return [[CLXInMobiRewardedFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiRewardedFactory"];
    }
    return self;
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                              bidId:(NSString *)bidId
                                                adm:(NSString *)adm
                                             extras:(NSDictionary<NSString *, NSString *> *)extras
                                       adUnitName:(NSString *)adUnitName
                                           delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded - Ad Unit: %@ (%@), BidID: %@",
                         adUnitName ?: @"(unknown)", adId, bidId]];

    long long inmobiPlacementID = [extras[@"placement_id"] longLongValue];

    NSData *bidPayloadData = nil;
    if (adm && adm.length > 0) {
        bidPayloadData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID = 0)
    // Validation errors will be reported in load() via delegate callback
    CLXInMobiRewarded *rewarded = [[CLXInMobiRewarded alloc] initWithBidPayload:bidPayloadData
                                                                     placementID:inmobiPlacementID  // May be 0 (invalid)
                                                                   adUnitName:adUnitName
                                                                           bidID:bidId
                                                                        delegate:delegate];

    return rewarded;
}

@end

