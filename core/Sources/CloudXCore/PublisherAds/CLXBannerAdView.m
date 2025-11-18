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
        
        // Set content hugging/compression priorities to ensure Auto Layout respects intrinsic size
        // This allows the view to work with both fixed constraints and flexible constraints
        [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return self;
}

#pragma mark - Auto Layout Support

- (CGSize)intrinsicContentSize {
    // Return the standard ad size based on banner type
    // This enables Auto Layout to properly size the banner view without
    // requiring host apps to explicitly set width/height constraints
    switch (self.adFormat) {
        case CLXBannerTypeMREC:
            return CGSizeMake(300, 250);
        case CLXBannerTypeW320H50:
        default:
            return CGSizeMake(320, 50);
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // Update visibility based on superview presence
    BOOL isVisible = (self.superview != nil && self.window != nil);
    if ([self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        [(CLXPublisherBanner *)self.banner setVisible:isVisible];
    }
    
    // Call didShowWithAd when banner is added to superview (becomes visible)
    if (self.superview && [self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        if ([self.banner respondsToSelector:@selector(didShowBanner:)]) {
            [(CLXPublisherBanner *)self.banner didShowBanner:nil];
        }
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
    [logger debug:@"[CloudXBannerAdView] didLoadBanner called"];
    
    UIView *bannerView = banner.bannerView;
    if (bannerView) {
        [logger debug:@"[CloudXBannerAdView] Adding banner view to view hierarchy"];
        
        bannerView.userInteractionEnabled = YES;
        [self addSubview:bannerView];
        
        // Check if adapter declares flexible sizing capability
        // Category default guarantees method exists - no need for respondsToSelector check
        BOOL isFlexible = [banner isFlexibleSize];
        
        [logger debug:[NSString stringWithFormat:@"[CloudXBannerAdView] Banner isFlexible: %d, size: %.0fx%.0f", 
                      isFlexible, bannerView.bounds.size.width, bannerView.bounds.size.height]];
        
        if (isFlexible) {
            // Flexible banner - stretch to fill container
            bannerView.frame = self.bounds;
            bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [logger debug:@"[CloudXBannerAdView] Flexible banner - stretching to container"];
        } else {
            // Fixed-size banner - center it
            CGSize bannerSize = bannerView.bounds.size;
            CGFloat x = (self.bounds.size.width - bannerSize.width) / 2.0;
            CGFloat y = (self.bounds.size.height - bannerSize.height) / 2.0;
            bannerView.frame = CGRectMake(x, y, bannerSize.width, bannerSize.height);
            [logger debug:[NSString stringWithFormat:@"[CloudXBannerAdView] Fixed-size banner - centering at x=%.0f", x]];
        }
        
        // Force layout update
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } else {
        [logger error:@"Banner view is nil, cannot add to hierarchy"];
    }
    
    // Note: didLoadWithAd: is called directly by CLXPublisherBanner, not here
    // This avoids duplicate delegate calls and ensures proper CLXAd is passed
}

- (void)failToLoadBanner:(id<CLXAdapterBanner>)banner error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(failToLoadWithAd:error:)]) {
        // Use stored ad if available, otherwise create a placeholder
        // Note: self.ad may be nil if this is the first load attempt
        CLXAd *adToPass = self.ad;
        if (!adToPass) {
            [logger warn:@"[CloudXBannerAdView] failToLoadBanner called with no ad object"];
        }
        [self.delegate failToLoadWithAd:adToPass error:error];
    }
}

- (void)didShowBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(didShowWithAd:)]) {
        // Use stored ad object (should be populated after didLoadWithAd)
        if (self.ad) {
            [self.delegate didShowWithAd:self.ad];
        } else {
            [logger error:@"didShowBanner called but self.ad is nil"];
        }
    }
}

- (void)impressionBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(impressionOn:)]) {
        // Use stored ad object (should be populated after didLoadWithAd)
        if (self.ad) {
            [self.delegate impressionOn:self.ad];
        } else {
            [logger error:@"impressionBanner called but self.ad is nil"];
        }
    }
}

- (void)clickBanner:(id<CLXAdapterBanner>)banner {
    if ([self.delegate respondsToSelector:@selector(didClickWithAd:)]) {
        // Use stored ad object (should be populated after didLoadWithAd)
        if (self.ad) {
            [self.delegate didClickWithAd:self.ad];
        } else {
            [logger error:@"clickBanner called but self.ad is nil"];
        }
    }
}

#pragma mark - BaseAdDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    [logger debug:@"[CloudXBannerAdView] didLoadWithAd called - displaying banner"];
    
    // Store the ad object for use in other delegate methods
    // This fixes the unsafe cast bug and enables proper ad metadata access
    _ad = ad;
    
    // Get the banner view from the underlying banner (CLXPublisherBanner)
    if ([self.banner isKindOfClass:[CLXPublisherBanner class]]) {
        CLXPublisherBanner *publisherBanner = (CLXPublisherBanner *)self.banner;
        
        // Get the current banner adapter that has the view to display
        id<CLXAdapterBanner> currentBanner = publisherBanner.bannerOnScreen;
        if (!currentBanner) {
            currentBanner = publisherBanner.prefetchedBanner;
        }
        
        if (currentBanner && currentBanner.bannerView) {
            [logger debug:@"[CloudXBannerAdView] Found banner view, adding to hierarchy"];
            
            // Remove any existing banner views to prevent duplicates
            for (UIView *subview in [self.subviews copy]) {
                [subview removeFromSuperview];
            }
            
            UIView *bannerView = currentBanner.bannerView;
            bannerView.userInteractionEnabled = YES;
            [self addSubview:bannerView];
            
            // Check if adapter declares flexible sizing capability
            // Category default guarantees method exists - no need for respondsToSelector check
            BOOL isFlexible = [currentBanner isFlexibleSize];
            
            [logger debug:[NSString stringWithFormat:@"[CloudXBannerAdView] currentBanner class: %@, isFlexibleSize: %d", 
                          [currentBanner class], isFlexible]];
            [logger debug:[NSString stringWithFormat:@"[CloudXBannerAdView] Banner size: %.0fx%.0f, will %@", 
                          bannerView.bounds.size.width, bannerView.bounds.size.height,
                          isFlexible ? @"stretch to container" : @"center in container"]];
            
            if (isFlexible) {
                // Flexible banner - stretch to fill container
                bannerView.frame = self.bounds;
                bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [logger debug:@"[CloudXBannerAdView] Flexible banner - stretching to container"];
            } else {
                // Fixed-size banner - center it
                CGSize bannerSize = bannerView.bounds.size;
                CGFloat x = (self.bounds.size.width - bannerSize.width) / 2.0;
                CGFloat y = (self.bounds.size.height - bannerSize.height) / 2.0;
                bannerView.frame = CGRectMake(x, y, bannerSize.width, bannerSize.height);
                [logger debug:[NSString stringWithFormat:@"[CloudXBannerAdView] Fixed-size banner - centering at x=%.0f", x]];
            }
            
            // Force layout update
            [self setNeedsLayout];
            [self layoutIfNeeded];
        } else {
            [logger error:@"No banner view available to display"];
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