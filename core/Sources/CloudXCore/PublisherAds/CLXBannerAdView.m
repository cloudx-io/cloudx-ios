/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXBannerAdView.m
 * @brief Banner ad view implementation
 */

#import <CloudXCore/CLXBannerAdView.h>
#import <CloudXCore/CLXBanner.h>
#import <CloudXCore/CLXBannerDelegate.h>
#import <CloudXCore/CLXBannerType.h>
#import <CloudXCore/CLXAdapterBanner.h>
#import <CloudXCore/CLXPublisherBanner.h>
#import <CloudXCore/CLXLogger.h>
#import <UIKit/UIKit.h>

// Category to expose internal methods for banner view access
@interface CLXPublisherBanner (CLXBannerVisibility)
- (void)_internal_setVisible:(BOOL)visible;
@end

// Category to expose internal banner adapter properties
@interface CLXPublisherBanner (CLXBannerAdViewAccess)
@property (nonatomic, strong, nullable, readonly) id<CLXAdapterBanner> bannerOnScreen;
@property (nonatomic, strong, nullable, readonly) id<CLXAdapterBanner> prefetchedBanner;
@end

@interface CLXBannerAdView () <CLXAdapterBannerDelegate>

@property (nonatomic, strong) id<CLXBanner> banner;
@property (nonatomic, strong, readwrite) CLXAd *ad;
@property (nonatomic, copy, readwrite) NSString *adUnitIdentifier;
@property (nonatomic, assign, readwrite) CLXBannerType adFormat;

@end

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"BannerAdView.m"];
}

@implementation CLXBannerAdView

- (instancetype)initWithBanner:(id<CLXBanner>)banner type:(CLXBannerType)type delegate:(id<CLXBannerDelegate>)delegate {
    CGSize size = CGSizeZero;
    switch (type) {
        case CLXBannerTypeMREC:
            size = CGSizeMake(300, 250);
            break;
        case CLXBannerTypeW320H50:
        default:
            size = CGSizeMake(320, 50);
            break;
    }
    self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    if (self) {
        _banner = banner;
        _delegate = delegate;
        _adFormat = type;
        _suspendPreloadWhenInvisible = YES;
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        
        // Set up the underlying ad instance if banner is a CLXAd
        if ([banner isKindOfClass:[CLXAd class]]) {
            _ad = (CLXAd *)banner;
        }
        
        // Extract adUnitIdentifier from banner if it's a CLXPublisherBanner
        if ([banner respondsToSelector:@selector(placementID)]) {
            _adUnitIdentifier = [(CLXPublisherBanner *)banner placementID];
        }
        
        _banner.delegate = self;
        if ([_banner respondsToSelector:@selector(setDelegate:)]) {
            [_banner setDelegate:self];
        }
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // Update visibility based on superview presence
    BOOL isVisible = (self.superview != nil && self.window != nil);
    if ([self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        [(CLXPublisherBanner *)self.banner setVisible:isVisible];
    }
    
    if (self.superview) {
        [self.banner load];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    // Update visibility based on window presence
    BOOL isVisible = (self.superview != nil && self.window != nil);
    if ([self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        [(CLXPublisherBanner *)self.banner setVisible:isVisible];
    }
}

- (void)setSuspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible {
    _suspendPreloadWhenInvisible = suspendPreloadWhenInvisible;
    self.banner.suspendPreloadWhenInvisible = suspendPreloadWhenInvisible;
}

- (void)load {
    // Delegate to the underlying banner since CLXAd is a data object
    [self.banner load];
}

- (void)destroy {
    // Set banner as not visible before destroying
    if ([self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        [(CLXPublisherBanner *)self.banner setVisible:NO];
    }
    
    [self removeFromSuperview];
    // Delegate to the underlying banner since CLXAd is a data object
    [self.banner destroy];
}

- (BOOL)isReady {
    // Delegate to the underlying banner since CLXAd is a data object
    return self.banner.isReady;
}

- (BOOL)isLoading {
    // Delegate to the underlying banner since CLXAd is a data object
    return self.banner.isLoading;
}

- (BOOL)isDestroyed {
    // Delegate to the underlying banner since CLXAd is a data object
    return self.banner.isDestroyed;
}

- (void)startAutoRefresh {
    // Delegate to the underlying banner for auto-refresh control
    if ([self.banner respondsToSelector:@selector(startAutoRefresh)]) {
        [(CLXPublisherBanner *)self.banner startAutoRefresh];
    }
}

- (void)stopAutoRefresh {
    // Delegate to the underlying banner for auto-refresh control
    if ([self.banner respondsToSelector:@selector(stopAutoRefresh)]) {
        [(CLXPublisherBanner *)self.banner stopAutoRefresh];
    }
}

#pragma mark - CLXAdapterBannerDelegate

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    [logger debug:@"🎯 [CloudXBannerAdView] didLoadBanner called"];
    
    UIView *bannerView = banner.bannerView;
    if (bannerView) {
        [logger debug:@"🎯 [CloudXBannerAdView] Adding banner view to view hierarchy"];
        
        bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        bannerView.userInteractionEnabled = YES;
        [self addSubview:bannerView];
        bannerView.frame = self.bounds;
        
        // Force layout update
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } else {
        [logger error:@"❌ [CloudXBannerAdView] Banner view is nil, cannot add to hierarchy"];
    }
    
    // Note: didLoadWithAd: is called directly by CLXPublisherBanner, not here
    // This avoids duplicate delegate calls and ensures proper CLXAd is passed
}

- (void)failToLoadBanner:(id<CLXAdapterBanner>)banner error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
        CLXAd *adToPass = self.ad ?: (CLXAd *)self.banner;
        [self.delegate failToLoadWithAd:adToPass error:error];
    }
}

- (void)didShowBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
        CLXAd *adToPass = self.ad ?: (CLXAd *)self.banner;
        [self.delegate didShowWithAd:adToPass];
    }
}

- (void)impressionBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
        CLXAd *adToPass = self.ad ?: (CLXAd *)self.banner;
        [self.delegate impressionOn:adToPass];
    }
}

- (void)clickBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
        CLXAd *adToPass = self.ad ?: (CLXAd *)self.banner;
        [self.delegate didClickWithAd:adToPass];
    }
}

- (void)closedByUserActionBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(closedByUserActionWithAd:)]) {
        CLXAd *adToPass = self.ad ?: (CLXAd *)self.banner;
        [self.delegate closedByUserActionWithAd:adToPass];
    }
}

#pragma mark - BaseAdDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    [logger debug:@"🎯 [CloudXBannerAdView] didLoadWithAd called - displaying banner"];
    
    // Get the banner view from the underlying banner (CLXPublisherBanner)
    if ([self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        CLXPublisherBanner *publisherBanner = (CLXPublisherBanner *)self.banner;
        
        // Get the current banner adapter that has the view to display
        id<CLXAdapterBanner> currentBanner = publisherBanner.bannerOnScreen;
        if (!currentBanner) {
            currentBanner = publisherBanner.prefetchedBanner;
        }
        
        if (currentBanner && currentBanner.bannerView) {
            [logger debug:@"🎯 [CloudXBannerAdView] Found banner view, adding to hierarchy"];
            
            // Remove any existing banner views to prevent duplicates
            for (UIView *subview in [self.subviews copy]) {
                [subview removeFromSuperview];
            }
            
            UIView *bannerView = currentBanner.bannerView;
            bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            bannerView.userInteractionEnabled = YES;
            [self addSubview:bannerView];
            bannerView.frame = self.bounds;
            
            // Force layout update
            [self setNeedsLayout];
            [self layoutIfNeeded];
        } else {
            [logger error:@"❌ [CloudXBannerAdView] No banner view available to display"];
        }
    }
    
    // Forward the callback to the external delegate
    if ([self.delegate respondsToSelector:@selector(didLoadWithAd:)]) {
        [self.delegate didLoadWithAd:ad];
    }
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
        [self.delegate failToLoadWithAd:ad error:error];
    }
}

- (void)didShowWithAd:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
        [self.delegate didShowWithAd:ad];
    }
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(failToShowWithAd:error:)]) {
        [self.delegate failToShowWithAd:ad error:error];
    }
}

- (void)didHideWithAd:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(didHideWithAd:)]) {
        [self.delegate didHideWithAd:ad];
    }
}

- (void)didClickWithAd:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
        [self.delegate didClickWithAd:ad];
    }
}

- (void)impressionOn:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
        [self.delegate impressionOn:ad];
    }
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(closedByUserActionWithAd:)]) {
        [self.delegate closedByUserActionWithAd:ad];
    }
}

- (void)revenuePaid:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(revenuePaid:)]) {
        [self.delegate revenuePaid:ad];
    }
}

- (void)didExpandAd:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(didExpandAd:)]) {
        [self.delegate didExpandAd:ad];
    }
}

- (void)didCollapseAd:(CLXAd *)ad {
    if ([self.delegate respondsToSelector:@selector(didCollapseAd:)]) {
        [self.delegate didCollapseAd:ad];
    }
}

@end 