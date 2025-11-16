#import "CLXMintegralInterstitialFactory.h"
#import "CLXMintegralInterstitial.h"
#import <CloudXCore/CLXError.h>

@implementation CLXMintegralInterstitialFactory

+ (instancetype)createInstance {
    return [[CLXMintegralInterstitialFactory alloc] init];
}

- (NSString *)network {
    return @"mintegral";
}

- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                           bidPayload:(nullable NSString *)bidPayload
                                                bidID:(NSString *)bidID
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating interstitial - AdId:%@", adId]];
    
    NSArray *components = [adId componentsSeparatedByString:@"_"];
    if (components.count < 2) {
        [self.logger error:@"Invalid ad ID format. Expected: placementID_unitID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid ad ID format. Expected: placementID_unitID"];
            [delegate didFailToLoadWithInterstitial:nil error:error];
        }
        return nil;
    }
    
    NSString *placementID = components[0];
    NSString *unitID = components[1];
    
    if (placementID.length == 0 || unitID.length == 0) {
        [self.logger error:@"Empty placement ID or unit ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Empty placement ID or unit ID"];
            [delegate didFailToLoadWithInterstitial:nil error:error];
        }
        return nil;
    }
    
    CLXMintegralInterstitial *interstitial = 
        [[CLXMintegralInterstitial alloc] initWithBidPayload:bidPayload
                                                 placementID:placementID
                                                      unitID:unitID
                                                       bidID:bidID
                                                    delegate:delegate];
    
    return interstitial;
}

@end

