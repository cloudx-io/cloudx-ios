//
//  CloudXPrebidBanner.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 compliant banner rendering implementation for CloudX Prebid Adapter
//  
//  This class provides complete banner ad rendering including:
//  - Prebid 3.0 compliant ad markup processing
//  - Advanced WebView-based rendering with MRAID 3.0 support
//  - Performance optimization and caching
//  - Viewability tracking with IAB compliance
//  - Close button management for expandable ads
//  - Comprehensive event delegation
//  - Error handling and validation
//  - Memory management and cleanup
//

#import "CLXPrebidBanner.h"
#import "CLXWKScriptHelper.h"
#import <SafariServices/SafariServices.h>
#import <CloudXCore/CLXLogger.h>

// Use our wrapper to avoid Swift dependencies
#import "../PrebidWrapper/CLXPrebidWebView.h"

/**
 * Private interface for CLXPrebidBanner
 * 
 * Contains internal properties for ad content, UI components,
 * and delegate management that should not be exposed publicly.
 */
@interface CLXPrebidBanner () <CLXPrebidWebViewDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, assign) BOOL hasClosedButton;
@property (nonatomic, strong) CLXPrebidWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXPrebidBanner

@synthesize delegate;
@synthesize timeout;

/**
 * Initialize CloudX Prebid Banner with ad markup and configuration
 * 
 * Sets up a complete banner ad environment including:
 * - Ad markup validation and processing
 * - WebView-based rendering with MRAID support
 * - Performance tracking and optimization
 * - Close button management for expandable ads
 * - Event delegation setup
 * - UI component initialization
 * 
 * @param adm Ad markup string (HTML/JavaScript content)
 * @param hasClosedButton Whether to show close button for expandable ads
 * @param type Banner type (standard, MREC, etc.)
 * @param viewController View controller for modal presentations
 * @param delegate Banner delegate for event callbacks
 * @return Initialized CLXPrebidBanner instance
 */
- (instancetype)initWithAdm:(NSString *)adm
             hasClosedButton:(BOOL)hasClosedButton
                        type:(CLXBannerType)type
               viewController:(UIViewController *)viewController
                     delegate:(id<CLXAdapterBannerDelegate>)delegate {
    self.logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidBanner"];
    [self.logger info:[NSString stringWithFormat:@"🚀 [INIT] CloudXPrebidBanner initialization started - Ad markup: %lu chars, Type: %ld, CloseBtn: %@, Delegate: %@", (unsigned long)adm.length, (long)type, hasClosedButton ? @"YES" : @"NO", delegate ? @"Present" : @"nil"]];
    
    // Start performance tracking for initialization
    [[CLXPerformanceManager sharedManager] startLoadTimerForKey:[NSString stringWithFormat:@"banner_%p", self]];
    
    self = [super init];
    if (self) {
        [self.logger info:@"✅ [INIT] Super init successful, setting properties"];
        
        // Configure core properties
        self.delegate = delegate;
        self.adm = adm;
        self.viewController = viewController;
        self.type = type;
        self.hasClosedButton = hasClosedButton;
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [INIT] Properties configured - Delegate: %@, Markup: %lu chars, VC: %@, Type: %ld, CloseBtn: %@", self.delegate ? @"Set" : @"nil", (unsigned long)self.adm.length, NSStringFromClass([self.viewController class]), (long)self.type, self.hasClosedButton ? @"YES" : @"NO"]];
        
        // Validate ad markup content
        if (!self.adm || self.adm.length == 0) {
            [self.logger error:@"❌ [INIT] Invalid ad markup - empty or nil"];
        } else {
            [self.logger info:[NSString stringWithFormat:@"✅ [INIT] Ad markup validated - %lu characters", (unsigned long)self.adm.length]];
        }
        
        // Create close button on main thread for UI safety
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.logger info:@"🔧 [INIT] Creating close button on main thread"];
            self.closeButton = [UIButton buttonWithType:UIButtonTypeClose];
            self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        });
        
        [self.logger info:[NSString stringWithFormat:@"🎯 [INIT] CloudXPrebidBanner initialization completed successfully - Banner instance ready: %p", self]];
    } else {
        [self.logger error:@"❌ [INIT] Super init failed - banner initialization failed"];
        [[CLXPerformanceManager sharedManager] endLoadTimerForKey:[NSString stringWithFormat:@"banner_%p", self]];
        return nil;
    }
    return self;
}

#pragma mark - CLXAdapterBanner

/**
 * Get the banner view for display
 * 
 * Returns the WebView containing the rendered ad content.
 * This is the main view that should be added to the view hierarchy.
 * 
 * @return UIView containing the rendered banner ad
 */
- (UIView *)bannerView {
    return self.webView;
}

/**
 * Get the SDK version string
 * 
 * Returns the current version of the CloudX Prebid Adapter SDK.
 * 
 * @return SDK version string
 */
- (NSString *)sdkVersion {
    return @"3.0.1";
}

/**
 * Load the banner ad into the WebView.
 * 
 * This method performs pre-load validation, calculates banner size,
 * creates the WebView, and loads the ad content.
 * It is typically called after initialization.
 */
- (void)load {
    [self.logger info:@"🚀 [LOAD] Banner load() method called"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [LOAD] Thread: %@, Instance: %p, Markup: %lu chars, Type: %ld, CloseBtn: %@, VC: %@, Delegate: %@", [NSThread currentThread].isMainThread ? @"Main" : @"Background", self, (unsigned long)self.adm.length, (long)self.type, self.hasClosedButton ? @"YES" : @"NO", self.viewController ? @"YES" : @"NO", self.delegate ? @"YES" : @"NO"]];
    
    // Pre-load validation
    if (!self.adm || self.adm.length == 0) {
        [self.logger error:@"❌ [LOAD] Cannot load - ad markup is empty or nil"];
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            NSError *error = [NSError errorWithDomain:@"CloudXPrebidBanner" code:400 userInfo:@{NSLocalizedDescriptionKey: @"Ad markup is empty or nil"}];
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    if (!self.viewController) {
        [self.logger error:@"❌ [LOAD] Cannot load - view controller is nil"];
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            NSError *error = [NSError errorWithDomain:@"CloudXPrebidBanner" code:401 userInfo:@{NSLocalizedDescriptionKey: @"View controller is nil"}];
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    [self.logger info:@"✅ [LOAD] Pre-load validation passed, proceeding with load"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Start render timer
        [[CLXPerformanceManager sharedManager] startRenderTimerForKey:[NSString stringWithFormat:@"banner_%p", self]];
        
        CGSize bannerSize = [self getBannerSizeForType:self.type];
        [self.logger debug:[NSString stringWithFormat:@"📊 [LOAD] Calculated banner size: %@", NSStringFromCGSize(bannerSize)]];
        
        if (bannerSize.width <= 0 || bannerSize.height <= 0) {
            [self.logger error:@"❌ [LOAD] Invalid banner size calculated"];
            if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
                NSError *error = [NSError errorWithDomain:@"CloudXPrebidBanner" code:402 userInfo:@{NSLocalizedDescriptionKey: @"Invalid banner size"}];
                [self.delegate failToLoadBanner:self error:error];
            }
            return;
        }
        
        CGRect frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        [self.logger debug:[NSString stringWithFormat:@"📊 [LOAD] WebView frame: %@, Creating CLXPrebidWebView with MRAID 3.0 support", NSStringFromCGRect(frame)]];
        self.webView = [[CLXPrebidWebView alloc] initWithFrame:frame placementType:CLXMRAIDPlacementTypeInline];
        
        if (self.webView) {
            [self.logger info:[NSString stringWithFormat:@"✅ [LOAD] CLXPrebidWebView created successfully: %p", self.webView]];
            self.webView.delegate = self;
            self.webView.scrollView.scrollEnabled = NO;
            self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            // Configure advanced features
            [self.logger info:@"🔧 [LOAD] Configuring advanced webview features - performance optimization, viewability tracking, resource preloading"];
            self.webView.optimizeForPerformance = YES;
            self.webView.enableViewabilityTracking = YES;
            self.webView.preloadResources = YES;
            self.webView.viewabilityStandard = CLXViewabilityStandardIAB;
            
            // Generate optimized HTML with performance enhancements
            [self.logger debug:@"🔧 [LOAD] Generating optimized HTML with viewport and styles..."];
            NSString *viewport = [NSString stringWithFormat:@"<meta name='viewport' content='width=%d, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>", (int)bannerSize.width];
            NSString *style = @"<style>"
                              @"html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }"
                              @"img { display: block; max-width: 100%; height: auto; }"
                              @"* { box-sizing: border-box; }"
                              @"body > * { max-width: 100%; }"
                              @"</style>";
            
            // Use performance manager to optimize HTML
            CLXPerformanceManager *perfManager = [CLXPerformanceManager sharedManager];
            NSString *optimizedAdm = [perfManager optimizeHTMLContent:self.adm forSize:bannerSize];
            
            // Use original adm if optimization failed
            if (!optimizedAdm) {
                optimizedAdm = self.adm ?: @"";
                [self.logger debug:@"⚠️ [LOAD] HTML optimization failed, using original ad markup"];
            }
            
            NSString *htmlString = [NSString stringWithFormat:@"<!DOCTYPE html><html><head>%@%@</head><body>%@</body></html>", viewport, style, optimizedAdm];
            
            [self.logger info:[NSString stringWithFormat:@"✅ [LOAD] HTML generated - Total: %lu chars, Optimized markup: %lu chars, Preview: %@...", (unsigned long)htmlString.length, (unsigned long)optimizedAdm.length, [htmlString substringToIndex:MIN(200, htmlString.length)]]];
            
            // Check for video content
            BOOL hasVideo = [self.adm containsString:@"<video"] || [self.adm containsString:@"<VAST"] || [self.adm containsString:@".mp4"] || [self.adm containsString:@".webm"];
            if (hasVideo) {
                [self.logger info:@"📹 [LOAD] Video content detected in ad markup"];
                self.webView.allowsInlineMediaPlayback = YES;
                self.webView.requiresUserActionForPlayback = NO;
            }
            
            // Check for MRAID content
            BOOL hasMRAID = [self.adm containsString:@"mraid"] || [self.adm containsString:@"expand"] || [self.adm containsString:@"resize"];
            if (hasMRAID) {
                [self.logger info:@"📱 [LOAD] MRAID content detected in ad markup"];
            }
            
            [self.logger info:@"🚀 [LOAD] Loading HTML into CLXPrebidWebView with advanced features enabled"];
            // Use CLXPrebidWebView's loadOptimizedHTML method for best performance
            [self.webView loadOptimizedHTML:htmlString baseURL:nil completion:^(BOOL success, NSError *error) {
                if (success) {
                    [self.logger info:@"✅ [LOAD] HTML loaded successfully into webview"];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"❌ [LOAD] Failed to load HTML: %@", error.localizedDescription]];
                }
            }];
            
            if (@available(iOS 16.4, *)) {
                self.webView.inspectable = YES;
                [self.logger debug:@"📊 [TestVastNetworkBanner] WebView inspectable enabled"];
            }
            
            if (self.hasClosedButton) {
                [self.logger debug:@"🔧 [TestVastNetworkBanner] Adding close button..."];
                [self.closeButton addTarget:self action:@selector(closeBanner:) forControlEvents:UIControlEventTouchUpInside];
                [self.webView addSubview:self.closeButton];
                
                [NSLayoutConstraint activateConstraints:@[
                    [self.webView.trailingAnchor constraintEqualToAnchor:self.closeButton.trailingAnchor],
                    [self.webView.topAnchor constraintEqualToAnchor:self.closeButton.topAnchor]
                ]];
                [self.logger info:@"✅ [TestVastNetworkBanner] Close button added and constrained"];
            } else {
                [self.logger debug:@"📊 [TestVastNetworkBanner] No close button needed"];
            }
            
            [self.logger info:@"✅ [TestVastNetworkBanner] Banner load setup completed"];
        } else {
            [self.logger error:@"❌ [TestVastNetworkBanner] Failed to create WKWebView"];
        }
    });
}

/**
 * Show the banner ad from a given view controller.
 * 
 * This method is typically called after the banner has been loaded.
 * It notifies the delegate of the show event.
 * 
 * @param viewController The view controller from which to present the banner.
 */
- (void)showFromViewController:(UIViewController *)viewController {
    // Banner is already shown when loaded, this method is called for consistency
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
}

/**
 * Destroy the banner ad and clean up resources.
 * 
 * Removes the WebView from its superview and invalidates its delegate.
 */
- (void)destroy {
    [self.webView removeFromSuperview];
    self.webView.delegate = nil;
    self.webView = nil;
}

#pragma mark - Private Methods

/**
 * Handle close button tap to destroy the banner.
 * 
 * This method is called when the user taps the close button.
 * It destroys the banner and notifies the delegate.
 * 
 * @param sender The UIButton that triggered the close action.
 */
- (void)closeBanner:(UIButton *)sender {
    [self destroy];
    if ([self.delegate respondsToSelector:@selector(closedByUserActionBanner:)]) {
        [self.delegate closedByUserActionBanner:self];
    }
}

/**
 * Helper method to calculate the size for a given banner type.
 * 
 * @param type The type of banner (e.g., standard, MREC).
 * @return CGSize appropriate for the banner type.
 */
- (CGSize)getBannerSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeMREC:
            return CGSizeMake(300, 250);
        default:
            return CGSizeMake(320, 50);
    }
}

@end

#pragma mark - CLXPrebidWebViewDelegate

@implementation CLXPrebidBanner (CLXPrebidWebViewDelegate)

/**
 * Get the view controller for presenting modals.
 * 
 * This method is required by CLXPrebidWebViewDelegate to present modal
 * content like SafariViewController.
 * 
 * @return UIViewController for presenting modals.
 */
- (UIViewController *)viewControllerForPresentingModals {
    [self.logger debug:@"🔧 [TestVastNetworkBanner] viewControllerForPresentingModals called"];
    return self.viewController;
}

/**
 * Notify when the WebView is ready to display the banner.
 * 
 * This method is called when the WebView has finished loading and is ready
 * to be displayed to the user. It ends performance timers and logs metrics.
 * 
 * @param webView The CLXPrebidWebView that is ready.
 */
- (void)webViewReadyToDisplay:(CLXPrebidWebView *)webView {
    [self.logger info:@"🎉 [SUCCESS] webViewReadyToDisplay called - banner is ready!"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [SUCCESS] CLXPrebidWebView: %p", webView]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [SUCCESS] Banner instance: %p", self]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [SUCCESS] Delegate available: %@", self.delegate ? @"YES" : @"NO"]];
    
    // End performance timers
    NSString *timerKey = [NSString stringWithFormat:@"banner_%p", self];
    [[CLXPerformanceManager sharedManager] endLoadTimerForKey:timerKey];
    [[CLXPerformanceManager sharedManager] endRenderTimerForKey:timerKey];
    
    // Log performance metrics
    CLXPerformanceMetrics *metrics = [[CLXPerformanceManager sharedManager] metrics];
    [self.logger info:[NSString stringWithFormat:@"⏱️ [PERFORMANCE] Load time: %.3f seconds", metrics.loadTime]];
    [self.logger info:[NSString stringWithFormat:@"⏱️ [PERFORMANCE] Render time: %.3f seconds", metrics.renderTime]];
    
    [self.logger debug:@"🔧 [SUCCESS] Notifying delegate: didLoadBanner..."];
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.logger info:@"✅ [DELEGATE] Calling didLoadBanner on delegate"];
        [self.delegate didLoadBanner:self];
        [self.logger debug:@"✅ [DELEGATE] didLoadBanner call completed"];
    } else {
        [self.logger info:@"⚠️ [DELEGATE] Delegate does not respond to didLoadBanner"];
    }
    
    [self.logger info:@"🎯 [SUCCESS] Banner load sequence completed successfully"];
}

/**
 * Handle errors during WebView loading.
 * 
 * This method is called if the WebView fails to load the ad content.
 * It ends performance timers and logs the error.
 * 
 * @param webView The CLXPrebidWebView that failed to load.
 * @param error The NSError describing the failure.
 */
- (void)webView:(CLXPrebidWebView *)webView failedToLoadWithError:(NSError *)error {
    [self.logger error:@"❌ [ERROR] Banner failed to load - webView error occurred"];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] WebView: %p", webView]];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] Banner instance: %p", self]];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] Error domain: %@", error.domain]];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] Error code: %ld", (long)error.code]];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] Error description: %@", error.localizedDescription]];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] Error failure reason: %@", error.localizedFailureReason ?: @"None"]];
    [self.logger error:[NSString stringWithFormat:@"📊 [ERROR] Error user info: %@", error.userInfo]];
    
    // End performance timers on failure
    NSString *timerKey = [NSString stringWithFormat:@"banner_%p", self];
    [[CLXPerformanceManager sharedManager] endLoadTimerForKey:timerKey];
    [[CLXPerformanceManager sharedManager] endRenderTimerForKey:timerKey];
    
    // Log attempted ad markup for debugging
    if (self.adm && self.adm.length > 0) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [ERROR] Ad markup that failed to load: %@", 
                      [self.adm substringToIndex:MIN(300, self.adm.length)]]];
    } else {
        [self.logger error:@"📊 [ERROR] Ad markup was empty or nil"];
    }
    
    [self.logger debug:@"🔧 [ERROR] Notifying delegate of failure..."];
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.logger error:@"📞 [DELEGATE] Calling failToLoadBanner:error: on delegate"];
        [self.delegate failToLoadBanner:self error:error];
        [self.logger debug:@"✅ [DELEGATE] failToLoadBanner:error: call completed"];
    } else {
        [self.logger error:@"⚠️ [DELEGATE] Delegate does not respond to failToLoadBanner:error: - no error callback available"];
    }
    
    [self.logger error:@"🔚 [ERROR] Banner error handling completed"];
}

/**
 * Handle click-through link events.
 * 
 * This method is called when the user taps on a click-through link within
 * the WebView. It opens the URL in a SafariViewController.
 * 
 * @param webView The CLXPrebidWebView that received the click.
 * @param url The NSURL of the click-through link.
 */
- (void)webView:(CLXPrebidWebView *)webView receivedClickthroughLink:(NSURL *)url {
    [self.logger info:@"✅ [TestVastNetworkBanner] webView:receivedClickthroughLink called"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [TestVastNetworkBanner] URL: %@", url]];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.logger info:@"✅ [TestVastNetworkBanner] Calling delegate clickBanner"];
        [self.delegate clickBanner:self];
    }
    
    // Open the URL in Safari
    dispatch_async(dispatch_get_main_queue(), ^{
        SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
        config.entersReaderIfAvailable = YES;
        
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url configuration:config];
        [self.viewController presentViewController:safariVC animated:YES completion:nil];
    });
}

// MRAID and rewarded events are handled internally by CLXPrebidWebView

@end 