#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralBanner.h"
#import <CloudXCore/CLXError.h>

@implementation CLXMintegralBannerFactory

+ (instancetype)createInstance {
    return [[CLXMintegralBannerFactory alloc] init];
}

- (NSString *)network {
    return @"mintegral";
}

- (nullable id<CLXAdapterBanner>)createWithAdId:(NSString *)adId
                                     bidPayload:(nullable NSString *)bidPayload
                                          bidID:(NSString *)bidID
                                           size:(CGSize)size
                                       delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating banner - AdId:%@, Size:%.0fx%.0f", adId, size.width, size.height]];
    
    NSArray *components = [adId componentsSeparatedByString:@"_"];
    if (components.count < 2) {
        [self.logger error:@"Invalid ad ID format. Expected: placementID_unitID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithBanner:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid ad ID format. Expected: placementID_unitID"];
            [delegate didFailToLoadWithBanner:nil error:error];
        }
        return nil;
    }
    
    NSString *placementID = components[0];
    NSString *unitID = components[1];
    
    if (placementID.length == 0 || unitID.length == 0) {
        [self.logger error:@"Empty placement ID or unit ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithBanner:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Empty placement ID or unit ID"];
            [delegate didFailToLoadWithBanner:nil error:error];
        }
        return nil;
    }
    
    CLXMintegralBanner *banner = 
        [[CLXMintegralBanner alloc] initWithBidPayload:bidPayload
                                           placementID:placementID
                                                unitID:unitID
                                                  size:size
                                                 bidID:bidID
                                              delegate:delegate];
    
    return banner;
}

@end

