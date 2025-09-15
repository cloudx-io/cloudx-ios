//
//  CLXVungleRewarded.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleRewarded.h"
#import "CLXVungleErrorHandler.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleRewarded ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, readwrite) NSString *bidID;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, assign, readwrite) BOOL isReady;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) BOOL hasRewarded;
@property (nonatomic, strong, nullable) NSTimer *timeoutTimer;
@end

@implementation CLXVungleRewarded

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _logger = [CLXLogger loggerWithTag:@"VungleRewarded"];
        _timeoutInterval = 30.0; // Default 30 second timeout
        _isReady = NO;
        _isLoaded = NO;
        _isShowing = NO;
        _isDestroyed = NO;
        _hasRewarded = NO;
        
        [_logger logDebug:[NSString stringWithFormat:@"Initialized Vungle rewarded - Placement: %@, BidID: %@, HasBidPayload: %@", 
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

#pragma mark - CLXAdapterRewarded Protocol

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
    
    [self.logger logInfo:[NSString stringWithFormat:@"Loading rewarded ad for placement: %@", self.placementID]];
    
    // Create Vungle rewarded
    self.rewarded = [[VungleRewarded alloc] initWithPlacementId:self.placementID];
    self.rewarded.delegate = self;
    
    // Start timeout timer
    [self startTimeoutTimer];
    
    // Load the ad
    if (self.bidPayload) {
        [self.logger logDebug:@"Loading with bid payload"];
        [self.rewarded load:self.bidPayload];
    } else {
        [self.logger logDebug:@"Loading waterfall ad"];
        [self.rewarded load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger logError:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    if (!self.isReady) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeShowFailed
                                         userInfo:@{NSLocalizedDescriptionKey: @"Ad not ready to show"}];
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
    
    [self.logger logInfo:@"Showing rewarded ad"];
    self.isShowing = YES;
    self.hasRewarded = NO;
    
    // Present the ad
    [self.rewarded presentWith:viewController];
}

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger logDebug:@"Destroying rewarded adapter"];
    self.isDestroyed = YES;
    
    // Cancel timeout timer
    [self cancelTimeoutTimer];
    
    // Clear delegate and cleanup
    if (self.rewarded) {
        self.rewarded.delegate = nil;
        self.rewarded = nil;
    }
    
    self.delegate = nil;
    self.isReady = NO;
    self.isLoaded = NO;
    self.isShowing = NO;
    self.hasRewarded = NO;
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(VungleRewarded *)rewarded {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring load callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Rewarded ad loaded successfully"];
    self.isLoaded = YES;
    self.isReady = YES;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded *)rewarded withError:(NSError *)error {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring load failure callback - adapter destroyed"];
        return;
    }
    
    [self handleLoadFailure:error];
}

- (void)rewardedAdWillPresent:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring will present callback - adapter destroyed"];
        return;
    }
    
    [self.logger logDebug:@"Rewarded ad will present"];
}

- (void)rewardedAdDidPresent:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring did present callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Rewarded ad presented successfully"];
    
    if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
        [self.delegate didShowWithRewarded:self];
    }
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded *)rewarded withError:(NSError *)error {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring present failure callback - adapter destroyed"];
        return;
    }
    
    [self handleShowFailure:error];
}

- (void)rewardedAdDidTrackImpression:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring impression callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Rewarded ad impression tracked"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)rewardedAdDidClick:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring click callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Rewarded ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)rewardedAdWillLeaveApplication:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring will leave app callback - adapter destroyed"];
        return;
    }
    
    [self.logger logDebug:@"Rewarded ad will leave application"];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring reward callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"User earned reward from rewarded ad"];
    self.hasRewarded = YES;
    
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:self];
    }
}

- (void)rewardedAdWillClose:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring will close callback - adapter destroyed"];
        return;
    }
    
    [self.logger logDebug:@"Rewarded ad will close"];
}

- (void)rewardedAdDidClose:(VungleRewarded *)rewarded {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring did close callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:[NSString stringWithFormat:@"Rewarded ad closed - User rewarded: %@", self.hasRewarded ? @"YES" : @"NO"]];
    self.isShowing = NO;
    self.isReady = NO; // Ad is consumed after showing
    self.isLoaded = NO;
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
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
    if (self.isReady || self.isDestroyed) {
        return;
    }
    
    [self.logger logWarning:[NSString stringWithFormat:@"Rewarded ad load timed out after %.1f seconds", self.timeoutInterval]];
    
    NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                         code:CLXVungleAdapterErrorCodeTimeout
                                     userInfo:@{NSLocalizedDescriptionKey: @"Ad load timed out"}];
    [self handleLoadFailure:error];
}

- (void)handleLoadFailure:(NSError *)error {
    self.isReady = NO;
    self.isLoaded = NO;
    
    NSError *mappedError = [CLXVungleErrorHandler handleVungleError:error
                                                         withLogger:self.logger
                                                            context:@"Rewarded"
                                                        placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:self error:mappedError];
    }
}

- (void)handleShowFailure:(NSError *)error {
    self.isShowing = NO;
    
    NSError *mappedError = [CLXVungleErrorHandler handleVungleError:error
                                                         withLogger:self.logger
                                                            context:@"Rewarded"
                                                        placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:mappedError];
    }
}

@end
