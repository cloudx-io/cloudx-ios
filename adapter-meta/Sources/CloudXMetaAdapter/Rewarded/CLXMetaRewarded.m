//
//  CLXMetaRewarded.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#if __has_include(<CloudXMetaAdapter/CLXMetaRewarded.h>)
#import <CloudXMetaAdapter/CLXMetaRewarded.h>
#else
#import "CLXMetaRewarded.h"
#endif
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMetaAdapter/CLXMetaInitializer.h>)
#import <CloudXMetaAdapter/CLXMetaInitializer.h>
#else
#import "CLXMetaInitializer.h"
#endif

// Import centralized error handler
#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "../Utils/CLXMetaErrorHandler.h"
#endif

// Import CloudXCore for both SPM and CocoaPods
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@interface CLXMetaRewarded ()

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXMetaRewarded

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(NSString *)placementID
                            bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaRewarded"];
        
        [self.logger debug:[NSString stringWithFormat:@"✅ [CLXMetaRewarded] Initialized for placement: %@ | bidPayload: %@", placementID, bidPayload ? @"YES" : @"NO"]];
        
        _rewarded = [[FBRewardedVideoAd alloc] initWithPlacementID:placementID];
        _rewarded.delegate = self;
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    BOOL ready = _rewarded && _rewarded.isAdValid;
    return ready;
}

- (void)load {
    // Prevent concurrent loading attempts
    if (_isLoading) {
        [self.logger debug:@"⚠️ [CLXMetaRewarded] Load already in progress, ignoring duplicate request"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"🔄 [CLXMetaRewarded] Loading ad for placement: %@ | bidPayload: %@", _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure Meta SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.rewarded loadAdWithBidPayload:self.bidPayload];
        } else {
            // For auto play video ads, it's recommended to load the ad at least 30 seconds before it is shown
            [self.rewarded loadAd];
        }
    });
}

- (void)loadAd {
    [self load];
}

// Server-side reward validation support (per Meta official docs)
- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency {
    if (_rewarded) {
        [_rewarded setRewardDataWithUserID:userID withCurrency:currency];
        [self.logger debug:[NSString stringWithFormat:@"✅ [CLXMetaRewarded] Reward data set for user: %@ | currency: %@", userID, currency]];
    } else {
        [self.logger error:@"⚠️ [CLXMetaRewarded] Cannot set reward data - rewarded ad not initialized"];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    // Check if rewarded video ad is valid before showing (per Meta official guidelines)
    if (!_rewarded || !_rewarded.isAdValid) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXMetaRewarded] Cannot show ad - rewarded exists: %@ | isValid: %@", _rewarded ? @"YES" : @"NO", _rewarded.isAdValid ? @"YES" : @"NO"]];
        
        // Create an error for show failure and call failure delegate
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                                description:@"Cannot show rewarded video - ad not ready or not valid"];
        
        [self.delegate didFailToShowWithRewarded:self error:showError];
        return;
    }
    
    [self.logger info:@"📊 [CLXMetaRewarded] Showing rewarded video ad"];
    [_rewarded showAdFromRootViewController:viewController];
}

- (void)destroy {
    self.rewarded = nil;
}

#pragma mark - FBRewardedVideoAdDelegate

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
    // Check if ad is valid before proceeding (per Meta official guidelines)
    if (!rewardedVideoAd.isAdValid) {
        [self.logger error:@"❌ [CLXMetaRewarded] Ad loaded but is not valid"];
        _isLoading = NO;
        
        // Create an error for invalid ad and call failure delegate
        NSError *invalidAdError = [CLXError errorWithCode:CLXErrorCodeInvalidAd 
                                                      description:@"Rewarded video ad loaded but is not valid"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:invalidAdError];
        }
        return;
    }
    
    [self.logger info:@"✅ [CLXMetaRewarded] Rewarded video ad loaded successfully"];
    
    // Reset loading state
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    // Use centralized error handler for comprehensive logging and error enhancement
    NSError *enhancedError = [CLXMetaErrorHandler handleMetaError:error
                                                       withLogger:self.logger
                                                          context:@"Rewarded"
                                                      placementID:self.placementID];
    
    // Reset loading state
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:self error:enhancedError];
    }
}

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"👆 [CLXMetaRewarded] Rewarded video ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"✅ [CLXMetaRewarded] Rewarded video ad closed"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"🔧 [CLXMetaRewarded] Rewarded video ad will close"];
    // Consider to add code here to resume your app's flow
}

- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"🎁 [CLXMetaRewarded] Rewarded video completed - reward earned"];
    
    // NOTE: This callback fires for client-side reward validation.
    // If server-side validation is enabled, rewards should only be granted
    // via rewardedVideoAdServerRewardDidSucceed callback instead.
    // For now, we'll trigger the reward since most publishers use client-side validation.
    
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:self];
        [self.logger info:@"✅ [CLXMetaRewarded] User reward granted via client-side validation"];
    }
}

// Missing delegate methods from official Meta implementation
- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"📊 [CLXMetaRewarded] Rewarded video impression logged"];
    
    // Forward to CloudX delegate if it supports impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)rewardedVideoAdServerRewardDidFail:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger error:@"❌ [CLXMetaRewarded] Server reward validation failed - no reward granted | Server-side validation failed, letting server handle reward validation via S2S callbacks if needed"];
}

- (void)rewardedVideoAdServerRewardDidSucceed:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"✅ [CLXMetaRewarded] Server reward validation succeeded"];
    
    // Following standard approach: Always grant reward when server validation passes
    // This mirrors industry standard behavior where rewards are granted after successful validation
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:self];
        [self.logger info:@"✅ [CLXMetaRewarded] User reward granted after server validation success"];
    }
}

@end 
