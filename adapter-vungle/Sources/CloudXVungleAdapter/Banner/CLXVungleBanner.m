//
//  CLXVungleBanner.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleBanner.h"
#import "CLXVungleErrorHandler.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleBanner ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, assign, readwrite) CLXBannerType bannerType;
@property (nonatomic, weak, readwrite) UIViewController *viewController;
@property (nonatomic, strong, nullable) VungleBannerView *vungleBannerView;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, strong, nullable) NSTimer *timeoutTimer;
@end

@implementation CLXVungleBanner

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type
                    viewController:(UIViewController *)viewController
                          delegate:(nullable id<CLXAdapterBannerDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];  // Now nullable - validation in load()
        _bidID = [bidID copy];
        _bannerType = type;
        _viewController = viewController;  // Now nullable - validation in load()
        _delegate = delegate;  // Now nullable - validation in load()
        _logger = [[CLXLogger alloc] initWithCategory:@"VungleBanner"];
        _timeoutInterval = 30.0; // Default 30 second timeout
        _isLoaded = NO;
        _isShowing = NO;
        _isDestroyed = NO;
        
        [_logger debug:[NSString stringWithFormat:@"Initialized Vungle banner - Placement: %@, BidID: %@, Type: %ld, HasBidPayload: %@", 
                          placementID ?: @"(nil)", bidID, (long)type, bidPayload ? @"YES" : @"NO"]];
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

- (BOOL)clx_isFlexibleSize {
    return NO;  // Vungle banners are fixed-size and should be centered
}

- (UIView *)bannerView {
    return self.vungleBannerView;
}

#pragma mark - CLXAdapterBanner Protocol

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (!self.placementID || self.placementID.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                     description:@"[Vungle] Invalid or missing placement ID for banner ad"];
        [self.logger error:error.localizedDescription];
        [self handleLoadFailure:error];
        return;
    }
    
    // Validate viewController at load time
    if (!self.viewController) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidConfiguration
                                     description:@"[Vungle] Missing viewController for banner ad"];
        [self.logger error:error.localizedDescription];
        [self handleLoadFailure:error];
        return;
    }
    
    // Validate delegate at load time
    if (!self.delegate) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidConfiguration
                                     description:@"[Vungle] Missing delegate for banner ad"];
        [self.logger error:error.localizedDescription];
        // Cannot call handleLoadFailure without delegate, just log
        return;
    }
    
    if (self.isDestroyed) {
        [self.logger error:@"Cannot load - adapter is destroyed"];
        return;
    }
    
    if (self.isLoaded) {
        [self.logger error:@"Ad already loaded, ignoring duplicate load request"];
        return;
    }
    
    // Check if Vungle SDK is initialized
    if (![VungleAds isInitialized]) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeNotInitialized
                                          userInfo:nil];
        [self handleLoadFailure:error];
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"Loading banner ad for placement: %@, isMainThread: %@", 
                       self.placementID, [NSThread isMainThread] ? @"YES" : @"NO"]];
    
    // Convert CloudX banner type to Vungle ad size
    VungleAdSize *vungleAdSize = [self vungleAdSizeFromBannerType:self.bannerType];
    if (!vungleAdSize) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeInvalidConfiguration
                                          userInfo:nil];
        [self handleLoadFailure:error];
        return;
    }
    
    // CRITICAL: VungleBannerView is a UIView - must be created and loaded on main thread!
    void (^createAndLoadBanner)(void) = ^{
        // Create Vungle banner view
        self.vungleBannerView = [[VungleBannerView alloc] initWithPlacementId:self.placementID
                                                                vungleAdSize:vungleAdSize];
        self.vungleBannerView.delegate = self;
        
        // Start timeout timer
        [self startTimeoutTimer];
        
        // Load the ad
        if (self.bidPayload) {
            [self.logger debug:@"Loading banner with bid payload"];
            [self.vungleBannerView load:self.bidPayload];
        } else {
            [self.logger debug:@"Loading waterfall banner ad"];
            [self.vungleBannerView load:nil];
        }
    };
    
    if ([NSThread isMainThread]) {
        createAndLoadBanner();
    } else {
        [self.logger debug:@"Not on main thread - dispatching VungleBannerView creation to main queue"];
        dispatch_async(dispatch_get_main_queue(), createAndLoadBanner);
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger error:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    if (!self.isLoaded) {
        [self.logger error:@"Banner not loaded, cannot show"];
        return;
    }
    
    if (self.isShowing) {
        [self.logger error:@"Banner is already showing"];
        return;
    }
    
    [self.logger info:@"Showing banner ad"];
    self.isShowing = YES;
    
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
}

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger debug:@"Destroying banner adapter"];
    self.isDestroyed = YES;
    
    // Cancel timeout timer
    [self cancelTimeoutTimer];
    
    // VungleBannerView is a UIView - must be cleaned up on main thread
    VungleBannerView *viewToDestroy = self.vungleBannerView;
    self.vungleBannerView = nil;
    self.delegate = nil;
    self.viewController = nil;
    self.isLoaded = NO;
    self.isShowing = NO;
    
    if (viewToDestroy) {
        if ([NSThread isMainThread]) {
            [viewToDestroy removeFromSuperview];
            viewToDestroy.delegate = nil;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [viewToDestroy removeFromSuperview];
                viewToDestroy.delegate = nil;
            });
        }
    }
}

#pragma mark - VungleBannerViewDelegate

- (void)bannerAdDidLoad:(VungleBannerView *)bannerView {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring load callback - adapter destroyed"];
        return;
    }
    
    [self.logger info:@"Banner ad loaded successfully"];
    self.isLoaded = YES;
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)bannerAdDidFail:(VungleBannerView *)bannerView withError:(NSError *)error {
    [self cancelTimeoutTimer];
    
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring load failure callback - adapter destroyed"];
        return;
    }
    
    [self handleLoadFailure:error];
}

- (void)bannerAdWillPresent:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring will present callback - adapter destroyed"];
        return;
    }
    
    [self.logger debug:@"Banner ad will present"];
}

- (void)bannerAdDidPresent:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring did present callback - adapter destroyed"];
        return;
    }
    
    [self.logger debug:@"Banner ad did present"];
    
    // Forward the display callback to the SDK
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
}

- (void)bannerAdDidTrackImpression:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring impression callback - adapter destroyed"];
        return;
    }
    
    [self.logger info:@"Banner ad impression tracked"];
    
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (void)bannerAdDidClick:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring click callback - adapter destroyed"];
        return;
    }
    
    [self.logger info:@"Banner ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)bannerAdWillLeaveApplication:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring will leave app callback - adapter destroyed"];
        return;
    }
    
    [self.logger debug:@"Banner ad will leave application"];
}

- (void)bannerAdWillClose:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring will close callback - adapter destroyed"];
        return;
    }
    
    [self.logger debug:@"Banner ad will close"];
}

- (void)bannerAdDidClose:(VungleBannerView *)bannerView {
    if (self.isDestroyed) {
        [self.logger debug:@"Ignoring did close callback - adapter destroyed"];
        return;
    }
    
    [self.logger info:@"Banner ad closed"];
    self.isShowing = NO;
    
    if ([self.delegate respondsToSelector:@selector(closedByUserActionBanner:)]) {
        [self.delegate closedByUserActionBanner:self];
    }
}

#pragma mark - Private Methods

- (nullable VungleAdSize *)vungleAdSizeFromBannerType:(CLXBannerType)bannerType {
    switch (bannerType) {
        case CLXBannerTypeW320H50:
            // W320H50 maps to regular banner (320x50) or leaderboard (728x90) on iPad
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                return [VungleAdSize VungleAdSizeLeaderboard]; // 728x90 on iPad
            } else {
                return [VungleAdSize VungleAdSizeBannerRegular]; // 320x50 on iPhone
            }
            
        case CLXBannerTypeMREC:
            return [VungleAdSize VungleAdSizeMREC]; // 300x250
            
        default:
            [self.logger error:[NSString stringWithFormat:@"Unsupported banner type: %ld", (long)bannerType]];
            return nil;
    }
}

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
    
    [self.logger error:[NSString stringWithFormat:@"Banner ad load timed out after %.1f seconds", self.timeoutInterval]];
    self.timeout = YES;
    
    NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                         code:CLXVungleAdapterErrorCodeTimeout
                                      userInfo:nil];
    [self handleLoadFailure:error];
}

- (void)handleLoadFailure:(NSError *)error {
    NSError *mappedError = [CLXVungleErrorHandler handleVungleError:error
                                                         withLogger:self.logger
                                                            context:@"Banner"
                                                        placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:mappedError];
    }
}

@end
