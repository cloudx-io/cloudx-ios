//
//  CLXInMobiNativeFactory.m
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiNativeFactory.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiNativeFactory.h>
#else
#import "CLXInMobiNativeFactory.h"
#endif

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiNative.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiNative.h>
#else
#import "CLXInMobiNative.h"
#endif

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiBaseFactory.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiBaseFactory.h>
#else
#import "../Base/CLXInMobiBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXInMobiNativeFactory ()
@property (nonatomic, strong) CLXInMobiBaseFactory *baseFactory;
@end

@implementation CLXInMobiNativeFactory

+ (instancetype)createInstance {
    return [[CLXInMobiNativeFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseFactory = [[CLXInMobiBaseFactory alloc] init];
    }
    return self;
}

- (nullable id<CLXAdapterNative>)createWithAdId:(NSString *)adId
                                    placementId:(NSString *)placementId
                                     bidPayload:(nullable NSString *)bidPayload
                                          bidID:(NSString *)bidID
                                       delegate:(id<CLXAdapterNativeDelegate>)delegate {
    
    [self.baseFactory.logger debug:[NSString stringWithFormat:@"Creating native - AdID: %@, Placement: %@", adId, placementId]];
    
    long long inmobiPlacementID = [self.baseFactory extractPlacementID:placementId];
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID"];
        return nil;
    }
    
    NSData *bidPayloadData = nil;
    if (bidPayload && bidPayload.length > 0) {
        bidPayloadData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    CLXInMobiNative *native = [[CLXInMobiNative alloc] initWithBidPayload:bidPayloadData
                                                               placementID:inmobiPlacementID
                                                                     bidID:bidID
                                                                  delegate:delegate];
    
    [self.baseFactory.logger debug:@"Native adapter created successfully"];
    
    return native;
}

@end

