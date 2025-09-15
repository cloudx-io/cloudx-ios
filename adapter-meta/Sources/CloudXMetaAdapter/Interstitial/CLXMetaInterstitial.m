//
//  CLXMetaInterstitial.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
// SPM requires angle brackets with module name, CocoaPods/Xcode supports quotes.
#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitial.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitial.h>
#else
#import "CLXMetaInterstitial.h"
#endif
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#if __has_include(<CloudXMetaAdapter/CLXMetaInitializer.h>)
#import <CloudXMetaAdapter/CLXMetaInitializer.h>
#else
#import "Initializers/CLXMetaInitializer.h"
#endif

// Import centralized error handler
#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "../Utils/CLXMetaErrorHandler.h"
#endif

NSString * const CLXMetaErrorDomain = @"CLXMetaErrorDomain";

@interface CLXMetaInterstitial () {
    NSString *_bidID;
}

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CLXMetaInterstitial

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(NSString *)placementID
                            bidID:(NSString *)bidID
                         delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaInterstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXMetaInterstitial] Init - PlacementID: %@, BidID: %@, HasBidPayload: %@", 
                           placementID, bidID, bidPayload ? @"YES" : @"NO"]];
        
        _interstitial = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
        _interstitial.delegate = self;
    }
    return self;
}

- (NSString *)bidID {
    [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXMetaInterstitial] bidID getter called - returning: %@", _bidID]];
    return _bidID;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    BOOL ready = _interstitial && _interstitial.isAdValid;
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXMetaInterstitial] isReady: %@", ready ? @"YES" : @"NO"]];
    return ready;
}

- (void)load {
    // Prevent concurrent loading attempts
    if (_isLoading) {
        [self.logger debug:@"⚠️ [CLXMetaInterstitial] Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXMetaInterstitial] Loading ad - Placement: %@, HasBidPayload: %@", 
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure Meta SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.interstitial loadAdWithBidPayload:self.bidPayload];
        } else {
            // loadAd will be deprecated so this shouldn't be hit
            [self.interstitial loadAd];
            [self.logger error:@"⚠️ [CLXMetaInterstitial] missing bid payload"];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];
    
    if (ready) {
        [self.logger info:@"🔧 [CLXMetaInterstitial] Showing interstitial ad"];
        
        // Call didShowWithAd before showing the ad
        if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [self.delegate didShowWithInterstitial:self];
        }
        
        [_interstitial showAdFromRootViewController:viewController];
    } else {
        [self.logger error:@"❌ [CLXMetaInterstitial] Cannot show ad - not ready"];
        
        // Create an error for show failure and call failure delegate
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                                description:@"Cannot show interstitial - ad not ready or not valid"];
        

        [self.delegate didFailToShowWithInterstitial:self error:showError];
    }
}

- (void)destroy {
    [self.logger debug:@"🧹 [CLXMetaInterstitial] Destroying interstitial"];
    
    if (self.interstitial) {
        // Properly clean up Meta SDK state
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    
    // Clear delegate to prevent callbacks after destruction
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"✅ [CLXMetaInterstitial] Destruction complete"];
}

#pragma mark - FBInterstitialAdDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    [self.logger info:[NSString stringWithFormat:@"🎉 [CLXMetaInterstitial] Loaded successfully - Valid: %@", interstitialAd.isAdValid ? @"YES" : @"NO"]];
    
    // Check if ad is valid before proceeding (per Meta official guidelines)
    if (!interstitialAd.isAdValid) {
        [self.logger error:@"❌ [CLXMetaInterstitial] Ad loaded but invalid"];
        _isLoading = NO;
        
        // Create an error for invalid ad and call failure delegate
        NSError *invalidAdError = [CLXError errorWithCode:CLXErrorCodeInvalidAd 
                                                      description:@"Interstitial ad loaded but is not valid"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            [self.delegate didFailToLoadWithInterstitial:self error:invalidAdError];
        }
        return;
    }
    
    // Reset loading state
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    // Use centralized error handler for comprehensive logging and error enhancement
    NSError *enhancedError = [CLXMetaErrorHandler handleMetaError:error
                                                       withLogger:self.logger
                                                          context:@"Interstitial"
                                                      placementID:self.placementID];
    
    // Reset loading state
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:enhancedError];
    }
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"✅ [CLXMetaInterstitial] Ad closed"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"🔧 [CLXMetaInterstitial] Ad will close"];
    // Consider to add code here to resume your app's flow
}

- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
    [self.logger info:[NSString stringWithFormat:@"📊 [CLXMetaInterstitial] Impression tracked - bidID: %@, self: %p | Forwarding to delegate: %@", 
                       self.bidID, self, [self.delegate respondsToSelector:@selector(impressionWithInterstitial:)] ? @"YES" : @"NO"]];
    
    // Forward to CloudX delegate if it supports impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"👆 [CLXMetaInterstitial] Ad clicked"];
    
    // Forward to CloudX delegate
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

@end 
