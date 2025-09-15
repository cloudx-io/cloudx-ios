//
//  CLXVungleInterstitial.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleInterstitial.h"
#import "CLXVungleErrorHandler.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleInterstitial ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, readwrite) NSString *bidID;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, strong, nullable) NSTimer *timeoutTimer;
@end

@implementation CLXVungleInterstitial

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _logger = [CLXLogger loggerWithTag:@"VungleInterstitial"];
        _timeoutInterval = 30.0; // Default 30 second timeout
        _isLoaded = NO;
        _isShowing = NO;
        _isDestroyed = NO;
        
        [_logger logDebug:[NSString stringWithFormat:@"Initialized Vungle interstitial - Placement: %@, BidID: %@, HasBidPayload: %@", 
                          placementID, bidID, bidPayload ? @"YES" : @"NO"]];
    }
    return self;
}

- (void)dealloc {
    [self destroy];
}

#pragma mark - Public Properties

- (NSString *)sdkVersion {
    return [VungleAds sdkVersion] ?: @"unknown";
}

- (NSString *)network {
    return @"Vungle";
}

#pragma mark - CLXAdapterInterstitial Protocol

- (void)load {
    if (self.isDestroyed) {
        [self.logger logError:@"Cannot load - adapter is destroyed"];
        return;
    }
    
    if (self.isLoaded) {
        [self.logger logWarning:@"Ad already loaded, ignoring duplicate load request"];
        return;
    }
    
    // Check if Vungle SDK is initialized
    if (![VungleAds isInitialized]) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeNotInitialized
                                         userInfo:@{NSLocalizedDescriptionKey: @"Vungle SDK not initialized"}];
        [self handleLoadFailure:error];
        return;
    }
    
    [self.logger logInfo:[NSString stringWithFormat:@"Loading interstitial ad for placement: %@", self.placementID]];
    
    // Create Vungle interstitial
    self.interstitial = [[VungleInterstitial alloc] initWithPlacementId:self.placementID];
    self.interstitial.delegate = self;
    
    // Start timeout timer
    [self startTimeoutTimer];
    
    // Load the ad
    if (self.bidPayload) {
        [self.logger logDebug:@"Loading with bid payload"];
        [self.interstitial load:self.bidPayload];
    } else {
        [self.logger logDebug:@"Loading waterfall ad"];
        [self.interstitial load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger logError:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    if (!self.isLoaded) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeShowFailed
                                         userInfo:@{NSLocalizedDescriptionKey: @"Ad not loaded"}];
        [self handleShowFailure:error];
        return;
    }
    
    if (self.isShowing) {
        [self.logger logWarning:@"Ad is already showing, ignoring duplicate show request"];
        return;
    }
    
    if (!viewController) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeShowFailed
                                         userInfo:@{NSLocalizedDescriptionKey: @"View controller is nil"}];
        [self handleShowFailure:error];
        return;
    }
    
    [self.logger logInfo:@"Showing interstitial ad"];
    self.isShowing = YES;
    
    // Present the ad
    [self.interstitial presentWith:viewController];
}

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger logDebug:@"Destroying interstitial adapter"];
    self.isDestroyed = YES;
    
    // Cancel timeout timer
    [self cancelTimeoutTimer];
    
    // Clear delegate and cleanup
    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    
    self.delegate = nil;
    self.isLoaded = NO;
    self.isShowing = NO;
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial *)interstitial {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring load callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Interstitial ad loaded successfully"];
    self.isLoaded = YES;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial *)interstitial withError:(NSError *)error {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring load failure callback - adapter destroyed"];
        return;
    }
    
    [self handleLoadFailure:error];
}

- (void)interstitialAdWillPresent:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring will present callback - adapter destroyed"];
        return;
    }
    
    [self.logger logDebug:@"Interstitial ad will present"];
    // Note: CloudX doesn't have a direct equivalent, but we can log this event
}

- (void)interstitialAdDidPresent:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring did present callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Interstitial ad presented successfully"];
    
    if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
        [self.delegate didShowWithInterstitial:self];
    }
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial *)interstitial withError:(NSError *)error {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring present failure callback - adapter destroyed"];
        return;
    }
    
    [self handleShowFailure:error];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring impression callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Interstitial ad impression tracked"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)interstitialAdDidClick:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring click callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Interstitial ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)interstitialAdWillLeaveApplication:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring will leave app callback - adapter destroyed"];
        return;
    }
    
    [self.logger logDebug:@"Interstitial ad will leave application"];
    // Note: CloudX doesn't have a direct equivalent for this callback
}

- (void)interstitialAdWillClose:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring will close callback - adapter destroyed"];
        return;
    }
    
    [self.logger logDebug:@"Interstitial ad will close"];
}

- (void)interstitialAdDidClose:(VungleInterstitial *)interstitial {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring did close callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Interstitial ad closed"];
    self.isShowing = NO;
    self.isLoaded = NO; // Ad is consumed after showing
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

#pragma mark - Private Methods

- (void)startTimeoutTimer {
    [self cancelTimeoutTimer];
    
    if (self.timeoutInterval > 0) {
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutInterval
                                                             target:self
                                                           selector:@selector(handleTimeout)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)cancelTimeoutTimer {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void)handleTimeout {
    if (self.isLoaded || self.isDestroyed) {
        return;
    }
    
    [self.logger logWarning:[NSString stringWithFormat:@"Interstitial ad load timed out after %.1f seconds", self.timeoutInterval]];
    self.timeout = YES;
    
    NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                         code:CLXVungleAdapterErrorCodeTimeout
                                     userInfo:@{NSLocalizedDescriptionKey: @"Ad load timed out"}];
    [self handleLoadFailure:error];
}

- (void)handleLoadFailure:(NSError *)error {
    NSError *mappedError = [CLXVungleErrorHandler handleVungleError:error
                                                         withLogger:self.logger
                                                            context:@"Interstitial"
                                                        placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:mappedError];
    }
}

- (void)handleShowFailure:(NSError *)error {
    self.isShowing = NO;
    
    NSError *mappedError = [CLXVungleErrorHandler handleVungleError:error
                                                         withLogger:self.logger
                                                            context:@"Interstitial"
                                                        placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:mappedError];
    }
}

@end
