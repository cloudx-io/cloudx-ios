//
//  CLXInMobiNativeFactory.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiNativeFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiNativeFactory.h>
#else
#import "CLXInMobiNativeFactory.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiNative.h>)
#import <CloudXInMobiAdapter/CLXInMobiNative.h>
#else
#import "CLXInMobiNative.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBaseFactory.h>)
#import <CloudXInMobiAdapter/CLXInMobiBaseFactory.h>
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
    
    // v1.3.0: No longer return nil for validation errors
    // Validation now happens in load() with proper error callbacks
    if (inmobiPlacementID == 0) {
        [self.baseFactory.logger error:@"Invalid placement ID - validation will be deferred to load()"];
    }
    
    NSData *bidPayloadData = nil;
    if (bidPayload && bidPayload.length > 0) {
        bidPayloadData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    // ALWAYS create and return adapter (even with invalid placementID = 0)
    // Validation errors will be reported in load() via delegate callback
    CLXInMobiNative *native = [[CLXInMobiNative alloc] initWithBidPayload:bidPayloadData
                                                               placementID:inmobiPlacementID  // May be 0 (invalid)
                                                                     bidID:bidID
                                                                  delegate:delegate];
    
    [self.baseFactory.logger debug:@"Native adapter created successfully"];
    
    return native;
}

@end

