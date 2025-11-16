//
//  CLXMolocoNativeFactory.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoNativeFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoNativeFactory.h>
#else
#import "CLXMolocoNativeFactory.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoNative.h>)
#import <CloudXMolocoAdapter/CLXMolocoNative.h>
#else
#import "CLXMolocoNative.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBaseFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBaseFactory.h>
#else
#import "../Base/CLXMolocoBaseFactory.h"
#endif

#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXMolocoNativeFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMolocoNativeFactory

+ (instancetype)createInstance {
    return [[CLXMolocoNativeFactory alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoNativeFactory"];
    }
    return self;
}

- (NSString *)network {
    return @"moloco";
}

- (nullable id<CLXAdapterNative>)createWithAdId:(NSString *)adId
                                     bidPayload:(nullable NSString *)bidPayload
                                          bidID:(NSString *)bidID
                                   adapterExtras:(nullable NSDictionary<NSString *, NSString *> *)adapterExtras
                                       delegate:(id<CLXAdapterNativeDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"Creating native ad - AdId: %@", adId]];
    
    NSString *placementID = [CLXMolocoBaseFactory resolveMolocoPlacementID:adapterExtras 
                                                               fallbackAdId:adId 
                                                                     logger:self.logger];
    
    if (!placementID || placementID.length == 0) {
        [self.logger error:@"Invalid placement ID"];
        if ([delegate respondsToSelector:@selector(didFailToLoadWithNative:error:)]) {
            NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                         description:@"Invalid placement ID"];
            [delegate didFailToLoadWithNative:nil error:error];
        }
        return nil;
    }
    
    CLXMolocoNative *native = 
        [[CLXMolocoNative alloc] initWithBidPayload:bidPayload
                                        placementID:placementID
                                              bidID:bidID
                                           delegate:delegate];
    
    return native;
}

@end

