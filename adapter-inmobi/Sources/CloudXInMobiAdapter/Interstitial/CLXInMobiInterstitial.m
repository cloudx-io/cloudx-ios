//
//  CLXInMobiInterstitial.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInterstitial.h>)
#import <CloudXInMobiAdapter/CLXInMobiInterstitial.h>
#else
#import "CLXInMobiInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "../Utils/CLXInMobiErrorHandler.h"
#endif

@interface CLXInMobiInterstitial () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) long long placementID;
@end

@implementation CLXInMobiInterstitial

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = @"10.8.8"; // InMobi SDK version
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInterstitial"];
        _timeoutInterval = 30.0; // Default 30 seconds
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %lld, BidID: %@, HasBidPayload: %@", 
                           placementID, bidID, bidPayload ? @"YES" : @"NO"]];
        
        // Create InMobi interstitial
        _interstitial = [[IMInterstitial alloc] initWithPlacementId:placementID];
        _interstitial.delegate = self;
    }
    return self;
}

- (NSString *)bidID {
    [self.logger debug:[NSString stringWithFormat:@"bidID getter called - returning: %@", _bidID]];
    return _bidID;
}

- (NSString *)network {
    return @"inmobi";
}

- (BOOL)isReady {
    BOOL ready = _interstitial && [_interstitial isReady];
    [self.logger debug:[NSString stringWithFormat:@"isReady: %@", ready ? @"YES" : @"NO"]];
    return ready;
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement: %lld, HasBidPayload: %@", 
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure InMobi SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.interstitial load:self.bidPayload];
        } else {
            [self.interstitial load];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];
    
    if (ready) {
        [self.logger info:@"Showing interstitial ad"];
        
        // Call didShowWithInterstitial before showing the ad
        if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [self.delegate didShowWithInterstitial:self];
        }
        
        [_interstitial showFromViewController:viewController withAnimation:kIMInterstitialAnimationTypeCoverVertical];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];
        
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                         description:@"Cannot show interstitial - ad not ready"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:showError];
        }
    }
}

- (void)destroy {
    [self.logger debug:@"Destroying interstitial"];
    
    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - IMInterstitialDelegate

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [self.logger info:[NSString stringWithFormat:@"Loaded successfully - Ready: %@", [interstitial isReady] ? @"YES" : @"NO"]];
    
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    
    _isLoading = NO;
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Interstitial Load"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:clxError];
    }
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [self.logger info:@"Interstitial presented"];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Interstitial Show"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:clxError];
    }
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
    [self.logger debug:@"Interstitial will present"];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.logger info:@"Interstitial dismissed"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
    [self.logger debug:@"Interstitial will dismiss"];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Interstitial clicked"];
    
    // InMobi fires this on click
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
    
    // Also fire impression (InMobi doesn't have separate impression callback)
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
    [self.logger debug:@"User will leave application"];
}

@end

