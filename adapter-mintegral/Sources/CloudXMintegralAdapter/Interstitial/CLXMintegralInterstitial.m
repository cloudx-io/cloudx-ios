#import "CLXMintegralInterstitial.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralInterstitial ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isDestroyed;
@end

@implementation CLXMintegralInterstitial

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _playVideoMute = NO;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralInterstitial"];
        _isDestroyed = NO;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@", placementID, unitID]];
    }
    return self;
}

- (void)load {
    if (self.isDestroyed) {
        [self.logger error:@"Cannot load - adapter is destroyed"];
        return;
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading interstitial - PlacementID:%@, UnitID:%@", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isDestroyed) {
            return;
        }
        
        // Create the interstitial manager on main thread if not already created
        if (!self.interstitialManager) {
            self.interstitialManager = [[MTGNewInterstitialBidAdManager alloc] initWithPlacementId:self.placementID 
                                                                                           unitId:self.unitID 
                                                                                         delegate:self];
        }
        
        // Apply mute setting before loading
        self.interstitialManager.playVideoMute = self.playVideoMute;
        
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.interstitialManager loadAdWithBidToken:self.bidPayload];
        } else {
            // Waterfall/non-bidding not supported with MTGNewInterstitialBidAdManager
            [self.logger error:@"Cannot load interstitial without bidPayload - requires bid token"];
            self.isLoading = NO;
            if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeLoadFailed
                                              description:@"Mintegral interstitial requires bid token for bidding flow"];
                [self.delegate didFailToLoadWithInterstitial:self error:error];
            }
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger error:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    BOOL ready = self.interstitialManager && [self.interstitialManager isAdReady];
    
    if (ready) {
        [self.logger info:@"Showing interstitial"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitialManager showFromViewController:viewController];
        });
    } else {
        [self.logger error:@"Cannot show - ad not ready"];
        
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdNotReady
                                     description:@"Interstitial not ready"];
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:error];
        }
    }
}

#pragma mark - MTGNewInterstitialBidAdDelegate

- (void)newInterstitialBidAdLoadSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Ad load success (waiting for resources)"];
}

- (void)newInterstitialBidAdResourceLoadSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Interstitial loaded successfully"];
    _isLoading = NO;
    
    // Retrieve creative ID
    _creativeID = [adManager getCreativeIdWithUnitId:adManager.currentUnitId];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didLoadWithInterstitial:self];
        });
    }
}

- (void)newInterstitialBidAdLoadFail:(nonnull NSError *)error adManager:(MTGNewInterstitialBidAdManager *)adManager {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Interstitial Load"
                                                            placementID:_placementID];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToLoadWithInterstitial:self error:mappedError];
        });
    }
}

- (void)newInterstitialBidAdShowSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Interstitial displayed"];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (!delegate) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [delegate didShowWithInterstitial:self];
        }
        
        if ([delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
            [delegate impressionWithInterstitial:self];
        }
    });
}

- (void)newInterstitialBidAdShowFail:(nonnull NSError *)error adManager:(MTGNewInterstitialBidAdManager *)adManager {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Interstitial Show"
                                                            placementID:_placementID];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToShowWithInterstitial:self error:mappedError];
        });
    }
}

- (void)newInterstitialBidAdClicked:(MTGNewInterstitialBidAdManager *)adManager {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Interstitial clicked"];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate clickWithInterstitial:self];
        });
    }
}

- (void)newInterstitialBidAdDismissedWithConverted:(BOOL)converted adManager:(MTGNewInterstitialBidAdManager *)adManager {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Interstitial hidden"];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didCloseWithInterstitial:self];
        });
    }
}

- (void)newInterstitialBidAdDidClosed:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Video completed"];
}

- (void)newInterstitialBidAdPlayCompleted:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Video play completed"];
}

- (void)newInterstitialBidAdEndCardShowSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"End card shown"];
}

#pragma mark - Lifecycle

- (void)dealloc {
    [self destroy];
}

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger debug:@"Destroying interstitial adapter"];
    self.isDestroyed = YES;
    
    if (self.interstitialManager) {
        self.interstitialManager = nil;
    }
    
    self.delegate = nil;
    self.isLoading = NO;
}

@end
