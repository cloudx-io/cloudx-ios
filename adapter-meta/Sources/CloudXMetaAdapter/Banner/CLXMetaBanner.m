//
//  CLXMetaBanner.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import "CLXMetaBanner.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

// Import internal headers
#if __has_include(<CloudXMetaAdapter/CLXMetaInitializer.h>)
#import <CloudXMetaAdapter/CLXMetaInitializer.h>
#else
#if __has_include("Initializers/CLXMetaInitializer.h")
#import "Initializers/CLXMetaInitializer.h"
#endif
#endif

// Import centralized error handler
#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "../Utils/CLXMetaErrorHandler.h"
#endif

@interface CLXMetaBanner ()

@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXMetaBanner

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                      placementID:(NSString *)placementID
                           bidID:(NSString *)bidID
                            type:(CLXBannerType)type
                   viewController:(UIViewController *)viewController
                        delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;
        _bidID = bidID;
        _type = type;
        _viewController = viewController;
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBanner"];
        
        [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXMetaBanner] Init - PlacementID: %@, BidID: %@, Type: %ld, HasBidPayload: %@", 
                           placementID, bidID, (long)type, bidPayload ? @"YES" : @"NO"]];
        
        // Ensure Facebook SDK initialization happens on main thread to prevent crashes
        if ([NSThread isMainThread]) {
            _bannerView = [[FBAdView alloc] initWithPlacementID:placementID
                                                          adSize:[self fbAdSizeForType:type]
                                              rootViewController:viewController];
            _bannerView.delegate = self;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self->_bannerView = [[FBAdView alloc] initWithPlacementID:placementID
                                                                    adSize:[self fbAdSizeForType:type]
                                                        rootViewController:viewController];
                self->_bannerView.delegate = self;
            });
        }
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    BOOL ready = self.bannerView != nil && self.bannerView.isAdValid;
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXMetaBanner] isReady: %@ (view: %@, valid: %@)", 
                       ready ? @"YES" : @"NO", self.bannerView ? @"YES" : @"NO", self.bannerView.isAdValid ? @"YES" : @"NO"]];
    return ready;
}

- (void)load {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXMetaBanner] Loading ad - Placement: %@, HasBidPayload: %@", 
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure Meta SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.bannerView loadAdWithBidPayload:self.bidPayload];
        } else {
            [self.bannerView loadAd];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (UIView *)adView {
    return _bannerView;
}

- (void)showFromViewController:(UIViewController *)viewController {
    UIViewController *vc = viewController ?: self.viewController;
    if (!vc || !self.bannerView) {
        [self.logger error:@"❌ [CLXMetaBanner] Cannot show ad - missing view controller or banner view"];
        return;
    }
    
    // Check if ad is valid before showing (per Meta official guidelines)
    if (!self.bannerView.isAdValid) {
        [self.logger error:@"❌ [CLXMetaBanner] Cannot show ad - not valid"];
        return;
    }
    
    [vc.view addSubview:self.bannerView];
    
    // Position banner at bottom of screen (can be customized)
    CGFloat bannerHeight = (_type == CLXBannerTypeMREC) ? 250 : 50;
    self.bannerView.frame = CGRectMake(0, vc.view.bounds.size.height - bannerHeight, vc.view.bounds.size.width, bannerHeight);
    
    [self.logger info:[NSString stringWithFormat:@"✅ [CLXMetaBanner] Banner displayed with frame: %@", NSStringFromCGRect(self.bannerView.frame)]];
}

- (void)destroy {
    if (self.bannerView) {
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
    }
}

#pragma mark - FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
    // Check if ad is valid before proceeding (per Meta official guidelines)
    if (!adView.isAdValid) {
        [self.logger error:@"❌ [CLXMetaBanner] Ad loaded but invalid"];
        
        // Create an error for invalid ad and call failure delegate
        NSError *invalidAdError = [CLXError errorWithCode:CLXErrorCodeInvalidAd 
                                                      description:@"Banner ad loaded but is not valid"];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:invalidAdError];
        }
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"✅ [CLXMetaBanner] Ad loaded successfully and is valid | Delegate responds to didLoadBanner: %@", 
                       [self.delegate respondsToSelector:@selector(didLoadBanner:)] ? @"YES" : @"NO"]];
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    } else {
        [self.logger error:@"❌ [CLXMetaBanner] Delegate does not respond to didLoadBanner"];
    }
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    // Use centralized error handler for comprehensive logging and error enhancement
    NSError *enhancedError = [CLXMetaErrorHandler handleMetaError:error
                                                       withLogger:self.logger
                                                          context:@"Banner"
                                                      placementID:self.placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:enhancedError];
    }
}

- (void)adViewDidClick:(FBAdView *)adView {
    [self.logger info:@"👆 [CLXMetaBanner] Ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
    // No logging needed for this callback
}

- (void)adViewWillLogImpression:(FBAdView *)adView {
    [self.logger info:@"📊 [CLXMetaBanner] Ad impression logged"];
    
    // Forward to CloudX delegate if it supports impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (FBAdSize)fbAdSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeW320H50:
            return kFBAdSizeHeight50Banner;
        case CLXBannerTypeMREC:
            return kFBAdSizeHeight250Rectangle;
        default:
            [self.logger error:[NSString stringWithFormat:@"⚠️ [CLXMetaBanner] Unknown banner type: %ld, defaulting to 50Banner", (long)type]];
            return kFBAdSizeHeight50Banner;
    }
}

@end 
