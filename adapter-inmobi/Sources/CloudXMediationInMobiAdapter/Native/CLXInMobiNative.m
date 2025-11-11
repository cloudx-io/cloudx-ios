//
//  CLXInMobiNative.m
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiNative.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiNative.h>
#else
#import "CLXInMobiNative.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "../Utils/CLXInMobiErrorHandler.h"
#endif

@interface CLXInMobiNative () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) long long placementID;
@end

@implementation CLXInMobiNative

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterNativeDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = @"10.8.8";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiNative"];
        _timeoutInterval = 30.0;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %lld, BidID: %@", placementID, bidID]];
        
        _native = [[IMNative alloc] initWithPlacementId:placementID];
        _native.delegate = self;
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading native - Placement: %lld", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.native load:self.bidPayload];
        } else {
            [self.native load];
        }
    });
}

- (void)destroy {
    [self.logger debug:@"Destroying native"];
    
    if (self.native) {
        self.native.delegate = nil;
        self.native = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - IMNativeDelegate

- (void)nativeDidFinishLoading:(IMNative *)native {
    [self.logger info:@"Native loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithNative:)]) {
        [self.delegate didLoadWithNative:self];
    }
}

- (void)native:(IMNative *)native didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Native Load"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithNative:error:)]) {
        [self.delegate didFailToLoadWithNative:self error:clxError];
    }
}

- (void)nativeWillPresentScreen:(IMNative *)native {
    [self.logger debug:@"Native will present screen"];
}

- (void)nativeDidPresentScreen:(IMNative *)native {
    [self.logger debug:@"Native did present screen"];
}

- (void)nativeWillDismissScreen:(IMNative *)native {
    [self.logger debug:@"Native will dismiss screen"];
}

- (void)nativeDidDismissScreen:(IMNative *)native {
    [self.logger debug:@"Native did dismiss screen"];
}

- (void)userWillLeaveApplicationFromNative:(IMNative *)native {
    [self.logger debug:@"User will leave application"];
}

- (void)native:(IMNative *)native didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Native clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
        [self.delegate clickWithNative:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
        [self.delegate impressionWithNative:self];
    }
}

@end

