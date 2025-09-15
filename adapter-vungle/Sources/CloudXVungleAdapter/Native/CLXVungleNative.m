//
//  CLXVungleNative.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleNative.h"
#import "CLXVungleErrorHandler.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleNative ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, strong, readwrite, nullable) UIView *nativeView;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) BOOL isRegistered;
@property (nonatomic, strong, nullable) NSTimer *timeoutTimer;
@end

@implementation CLXVungleNative

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterNativeDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _logger = [CLXLogger loggerWithTag:@"VungleNative"];
        _timeoutInterval = 30.0; // Default 30 second timeout
        _isLoaded = NO;
        _isShowing = NO;
        _isDestroyed = NO;
        _isRegistered = NO;
        
        [_logger logDebug:[NSString stringWithFormat:@"Initialized Vungle native - Placement: %@, BidID: %@, HasBidPayload: %@", 
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

- (nullable NSString *)title {
    return self.vungleNative.title;
}

- (nullable NSString *)bodyText {
    return self.vungleNative.bodyText;
}

- (nullable NSString *)callToAction {
    return self.vungleNative.callToAction;
}

- (nullable NSString *)advertiser {
    return self.vungleNative.advertiser;
}

- (double)starRating {
    return self.vungleNative.adStarRating;
}

- (nullable NSString *)sponsoredText {
    return self.vungleNative.sponsoredText;
}

#pragma mark - CLXAdapterNative Protocol

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
    
    [self.logger logInfo:[NSString stringWithFormat:@"Loading native ad for placement: %@", self.placementID]];
    
    // Create Vungle native
    self.vungleNative = [[VungleNative alloc] initWithPlacementId:self.placementID];
    self.vungleNative.delegate = self;
    
    // Start timeout timer
    [self startTimeoutTimer];
    
    // Load the ad
    if (self.bidPayload) {
        [self.logger logDebug:@"Loading native with bid payload"];
        [self.vungleNative load:self.bidPayload];
    } else {
        [self.logger logDebug:@"Loading waterfall native ad"];
        [self.vungleNative load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger logError:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    if (!self.isLoaded) {
        [self.logger logWarning:@"Native ad not loaded, cannot show"];
        return;
    }
    
    if (self.isShowing) {
        [self.logger logWarning:@"Native ad is already showing"];
        return;
    }
    
    [self.logger logInfo:@"Showing native ad"];
    self.isShowing = YES;
    
    // For native ads, "showing" means the ad is ready to be displayed
    // The actual display happens when registerViewForInteraction is called
    if ([self.delegate respondsToSelector:@selector(didShowWithNative:)]) {
        [self.delegate didShowWithNative:self];
    }
}

- (void)registerViewForInteraction:(UIView *)containerView
                         mediaView:(UIView *)mediaView
                     iconImageView:(nullable UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews {
    
    if (self.isDestroyed) {
        [self.logger logError:@"Cannot register view - adapter is destroyed"];
        return;
    }
    
    if (!self.isLoaded || !self.vungleNative) {
        [self.logger logError:@"Cannot register view - native ad not loaded"];
        return;
    }
    
    [self.logger logDebug:@"Registering native ad view for interaction"];
    
    // Store the native view reference
    self.nativeView = containerView;
    
    // Register with Vungle native ad
    if (clickableViews && clickableViews.count > 0) {
        [self.vungleNative registerViewForInteractionWithView:containerView
                                                    mediaView:(MediaView *)mediaView
                                                iconImageView:iconImageView
                                               viewController:viewController
                                               clickableViews:clickableViews];
    } else {
        [self.vungleNative registerViewForInteractionWithView:containerView
                                                    mediaView:(MediaView *)mediaView
                                                iconImageView:iconImageView
                                               viewController:viewController];
    }
    
    self.isRegistered = YES;
    
    // Set privacy icon position (top right is typical)
    self.vungleNative.adOptionsPosition = NativeAdOptionsPositionTopRight;
}

- (void)unregisterView {
    if (self.isDestroyed) {
        return;
    }
    
    if (self.vungleNative && self.isRegistered) {
        [self.logger logDebug:@"Unregistering native ad view"];
        [self.vungleNative unregisterView];
        self.isRegistered = NO;
    }
    
    self.nativeView = nil;
}

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger logDebug:@"Destroying native adapter"];
    self.isDestroyed = YES;
    
    // Cancel timeout timer
    [self cancelTimeoutTimer];
    
    // Unregister view
    [self unregisterView];
    
    // Clear delegate and cleanup
    if (self.vungleNative) {
        self.vungleNative.delegate = nil;
        self.vungleNative = nil;
    }
    
    self.delegate = nil;
    self.nativeView = nil;
    self.isLoaded = NO;
    self.isShowing = NO;
    self.isRegistered = NO;
}

#pragma mark - VungleNativeDelegate

- (void)nativeAdDidLoad:(VungleNative *)nativeAd {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring load callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Native ad loaded successfully"];
    self.isLoaded = YES;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithNative:)]) {
        [self.delegate didLoadWithNative:self];
    }
}

- (void)nativeAdDidFailToLoad:(VungleNative *)nativeAd withError:(NSError *)error {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring load failure callback - adapter destroyed"];
        return;
    }
    
    [self handleLoadFailure:error];
}

- (void)nativeAdDidFailToPresent:(VungleNative *)nativeAd withError:(NSError *)error {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring present failure callback - adapter destroyed"];
        return;
    }
    
    [self.logger logError:[NSString stringWithFormat:@"Native ad failed to present: %@", error.localizedDescription]];
    // Note: CloudX doesn't have a direct equivalent for native present failure
}

- (void)nativeAdDidTrackImpression:(VungleNative *)nativeAd {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring impression callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Native ad impression tracked"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
        [self.delegate impressionWithNative:self];
    }
}

- (void)nativeAdDidClick:(VungleNative *)nativeAd {
    if (self.isDestroyed) {
        [self.logger logDebug:@"Ignoring click callback - adapter destroyed"];
        return;
    }
    
    [self.logger logInfo:@"Native ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
        [self.delegate clickWithNative:self];
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
    
    [self.logger logWarning:[NSString stringWithFormat:@"Native ad load timed out after %.1f seconds", self.timeoutInterval]];
    self.timeout = YES;
    
    NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                         code:CLXVungleAdapterErrorCodeTimeout
                                     userInfo:@{NSLocalizedDescriptionKey: @"Native ad load timed out"}];
    [self handleLoadFailure:error];
}

- (void)handleLoadFailure:(NSError *)error {
    NSError *mappedError = [CLXVungleErrorHandler handleVungleError:error
                                                         withLogger:self.logger
                                                            context:@"Native"
                                                        placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadWithNative:error:)]) {
        [self.delegate failToLoadWithNative:self error:mappedError];
    }
}

@end
