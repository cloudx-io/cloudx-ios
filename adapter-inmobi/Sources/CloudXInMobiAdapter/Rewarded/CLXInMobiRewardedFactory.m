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

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBaseFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBaseFactory.h>
#else
#import "../Base/CLXInMobiBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXInMobiRewardedFactory ()
@property (nonatomic, strong) CLXInMobiBaseFactory *baseFactory;
@end

@implementation CLXInMobiRewardedFactory

+ (instancetype)createInstance {
    return [[CLXInMobiRewardedFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseFactory = [[CLXInMobiBaseFactory alloc] init];
    }
    return self;
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                       placementId:(NSString *)placementId
                                        bidPayload:(nullable NSString *)bidPayload
                                             bidID:(NSString *)bidID
                                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    [self.baseFactory.logger debug:[NSString stringWithFormat:@"Creating rewarded - AdID: %@, Placement: %@", adId, placementId]];
    
    long long inmobiPlacementID = [self.baseFactory extractPlacementID:placementId];
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID"];
        return nil;
    }
    
    NSData *bidPayloadData = nil;
    if (bidPayload && bidPayload.length > 0) {
        bidPayloadData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    CLXInMobiRewarded *rewarded = [[CLXInMobiRewarded alloc] initWithBidPayload:bidPayloadData
                                                                     placementID:inmobiPlacementID
                                                                           bidID:bidID
                                                                        delegate:delegate];
    
    [self.baseFactory.logger debug:@"Rewarded adapter created successfully"];
    
    return rewarded;
}

@end

