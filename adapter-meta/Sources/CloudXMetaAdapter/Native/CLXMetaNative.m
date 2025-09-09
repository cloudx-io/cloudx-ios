//
//  CLXMetaNative.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
// SPM requires angle brackets with module name, CocoaPods/Xcode supports quotes.
#if __has_include(<CloudXMetaAdapter/CLXMetaNative.h>)
#import <CloudXMetaAdapter/CLXMetaNative.h>
#else
#import "CLXMetaNative.h"
#endif
#import <CloudXCore/CLXLogger.h>
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
#if __has_include(<CloudXCore/CloudXCore-Swift.h>)
#import <CloudXCore/CloudXCore-Swift.h>
#else
#import <CloudXCore/CloudXCore.h>
#endif

@interface CLXMetaNative ()

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIView *_nativeView;
@property (nonatomic, assign) CLXNativeTemplate type;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CLXMetaNative

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(NSString *)placementID
                            bidID:(NSString *)bidID
                             type:(CLXNativeTemplate)type
                    viewController:(UIViewController *)viewController
                         delegate:(id<CLXAdapterNativeDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _bidID = [bidID copy];
        _type = type;
        _viewController = viewController;
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaNative"];
        
        [self.logger debug:[NSString stringWithFormat:@"✅ [CLXMetaNative] Initialized for placement: %@ | bidPayload: %@", placementID, bidPayload ? @"YES" : @"NO"]];
        
        _nativeAd = [[FBNativeAd alloc] initWithPlacementID:placementID];
        _nativeAd.delegate = self;
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    BOOL ready = _nativeAd && _nativeAd.isAdValid && __nativeView != nil;
    return ready;
}

- (UIView *)nativeView {
    return __nativeView;
}

- (void)load {
    [self loadAd];
}

- (void)loadAd {
    // Prevent concurrent loading attempts
    if (_isLoading) {
        [self.logger debug:@"⚠️ [CLXMetaNative] Load already in progress, ignoring duplicate request"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"🔄 [CLXMetaNative] Loading ad for placement: %@ | bidPayload: %@", _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure Meta SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.nativeAd loadAdWithBidPayload:self.bidPayload];
        } else {
            [self.nativeAd loadAd];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    UIViewController *vc = viewController ?: self.viewController;
    if (![self isReady] || !vc) return;
    UIView *nativeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, vc.view.bounds.size.width, 300)];
    [vc.view addSubview:nativeView];
    UIView *dummyMediaView = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *dummyIconView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.nativeAd registerViewForInteraction:nativeView
                                    mediaView:dummyMediaView
                                     iconView:dummyIconView
                              viewController:vc
                              clickableViews:@[]];
}

- (void)createNativeView {
    // Create a container view for the native ad
    __nativeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 300)];
    __nativeView.backgroundColor = [UIColor whiteColor];
    
    // Create UI elements following Meta's official native ad layout
    
    // 1. Icon view (FBMediaView for advertiser icon)
    FBMediaView *iconView = [[FBMediaView alloc] initWithFrame:CGRectMake(10, 10, 40, 40)];
    [__nativeView addSubview:iconView];
    
    // 2. Title label (advertiser name)
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, 250, 20)];
    titleLabel.text = _nativeAd.advertiserName ?: @"Advertiser";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor blackColor];
    [__nativeView addSubview:titleLabel];
    
    // 3. Sponsored label
    UILabel *sponsoredLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 30, 100, 15)];
    sponsoredLabel.text = _nativeAd.sponsoredTranslation ?: @"Sponsored";
    sponsoredLabel.font = [UIFont systemFontOfSize:12];
    sponsoredLabel.textColor = [UIColor grayColor];
    [__nativeView addSubview:sponsoredLabel];
    
    // 4. Ad Options View
    FBAdOptionsView *optionsView = [[FBAdOptionsView alloc] initWithFrame:CGRectMake(270, 30, 40, 15)];
    optionsView.nativeAd = _nativeAd;
    [__nativeView addSubview:optionsView];
    
    // 5. Cover media view (main ad content)
    FBMediaView *coverMediaView = [[FBMediaView alloc] initWithFrame:CGRectMake(10, 60, 300, 120)];
    coverMediaView.delegate = self; // Set delegate for aspect ratio handling
    [__nativeView addSubview:coverMediaView];
    
    // 6. Social context
    UILabel *socialContextLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 190, 300, 15)];
    socialContextLabel.text = _nativeAd.socialContext ?: @"";
    socialContextLabel.font = [UIFont systemFontOfSize:12];
    socialContextLabel.textColor = [UIColor grayColor];
    [__nativeView addSubview:socialContextLabel];
    
    // 7. Body text
    UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 210, 300, 40)];
    bodyLabel.text = _nativeAd.bodyText ?: @"Ad body text";
    bodyLabel.font = [UIFont systemFontOfSize:14];
    bodyLabel.textColor = [UIColor darkGrayColor];
    bodyLabel.numberOfLines = 2;
    [__nativeView addSubview:bodyLabel];
    
    // 8. Call to action button
    UIButton *ctaButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 260, 300, 30)];
    [ctaButton setTitle:_nativeAd.callToAction ?: @"Learn More" forState:UIControlStateNormal];
    [ctaButton setBackgroundColor:[UIColor systemBlueColor]];
    [ctaButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ctaButton.layer.cornerRadius = 6;
    [__nativeView addSubview:ctaButton];
    
    // Register the view for interaction - only CTA button and media view are clickable per Meta guidelines
    NSArray *clickableViews = @[ctaButton, coverMediaView];
    [_nativeAd registerViewForInteraction:__nativeView
                                mediaView:coverMediaView
                                 iconView:iconView
                          viewController:self.viewController
                          clickableViews:clickableViews];
    
    [self.logger debug:[NSString stringWithFormat:@"✅ [CLXMetaNative] Native view created with frame: %@", NSStringFromCGRect(__nativeView.frame)]];
}

- (void)destroy {
    // Remove nativeView from superview if it exists
    [__nativeView removeFromSuperview];
    __nativeView = nil;
    self.nativeAd = nil;
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
    [self.logger info:@"✅ [CLXMetaNative] Native ad loaded successfully"];
    
    // If there is an existing valid native ad, unregister the view (per Meta guidelines)
    if (self.nativeAd && self.nativeAd.isAdValid) {
        [self.nativeAd unregisterView];
    }
    
    // Retain a reference to the native ad object
    self.nativeAd = nativeAd;
    
    // Reset loading state
    _isLoading = NO;
    
    // Create the native view with Meta's native ad content
    [self createNativeView];
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithNative:)]) {
        [self.delegate didLoadWithNative:self];
    }
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
    // Use centralized error handler for comprehensive logging and error enhancement
    NSError *enhancedError = [CLXMetaErrorHandler handleMetaError:error
                                                       withLogger:self.logger
                                                          context:@"Native"
                                                      placementID:self.placementID];
    
    // Reset loading state
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(failToLoadWithNative:error:)]) {
        [self.delegate failToLoadWithNative:self error:enhancedError];
    }
}

- (void)nativeAdDidClick:(FBNativeAd *)nativeAd {
    [self.logger info:@"👆 [CLXMetaNative] Native ad clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
        [self.delegate clickWithNative:self];
    }
}

- (void)nativeAdDidFinishHandlingClick:(FBNativeAd *)nativeAd {
    [self.logger info:@"✅ [CLXMetaNative] Native ad finished handling click"];
}

- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd {
    [self.logger info:@"📊 [CLXMetaNative] Native ad impression logged"];
    
    // Forward to CloudX delegate if it supports impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
        [self.delegate impressionWithNative:self];
    }
}

#pragma mark - FBMediaViewDelegate

- (void)mediaViewDidLoad:(FBMediaView *)mediaView {
    // Apply natural width/height if needed for better layout
    CGFloat actualAspect = mediaView.aspectRatio;
    if (actualAspect > 0.0) {
        // You can uncomment these if you want to apply natural dimensions
        // [mediaView applyNaturalWidth];
        // [mediaView applyNaturalHeight];
    }
}

@end 
