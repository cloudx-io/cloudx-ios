#import "CLXMintegralRewardedFactory.h"
#import "CLXMintegralRewarded.h"
#import <CloudXCore/CLXError.h>

@implementation CLXMintegralRewardedFactory

+ (instancetype)createInstance {
    return [[CLXMintegralRewardedFactory alloc] init];
}

- (NSString *)network {
    return @"mintegral";
}

- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                       bidPayload:(nullable NSString *)bidPayload
                                            bidID:(NSString *)bidID
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating rewarded - AdId:%@", adId]];
    
    NSArray *components = [adId componentsSeparatedByString:@"_"];
    if (components.count < 2) {
        [self.logger error:@"Invalid ad ID format. Expected: placementID_unitID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid ad ID format. Expected: placementID_unitID"];
            [delegate didFailToLoadWithRewarded:nil error:error];
        }
        return nil;
    }
    
    NSString *placementID = components[0];
    NSString *unitID = components[1];
    
    if (placementID.length == 0 || unitID.length == 0) {
        [self.logger error:@"Empty placement ID or unit ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Empty placement ID or unit ID"];
            [delegate didFailToLoadWithRewarded:nil error:error];
        }
        return nil;
    }
    
    CLXMintegralRewarded *rewarded = 
        [[CLXMintegralRewarded alloc] initWithBidPayload:bidPayload
                                             placementID:placementID
                                                  unitID:unitID
                                                   bidID:bidID
                                                delegate:delegate];
    
    return rewarded;
}

@end

