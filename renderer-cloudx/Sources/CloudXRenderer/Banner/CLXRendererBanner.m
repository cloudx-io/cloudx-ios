//
//  CLXRendererBanner.m
//  CloudXRenderer
//
//  Renderer compliant banner rendering implementation for CloudX Renderer
//  
//  This class provides complete banner ad rendering including:
//  - Renderer compliant ad markup processing
//  - Advanced WebView-based rendering with MRAID 3.0 support
//  - Performance optimization and caching
//  - Viewability tracking with IAB compliance
//  - Close button management for expandable ads
//  - Comprehensive event delegation
//  - Error handling and validation
//  - Memory management and cleanup
//

#import "CLXRendererBanner.h"
#import "CLXWKScriptHelper.h"
#import "CLXRendererVersion.h"
#import <SafariServices/SafariServices.h>
#import <CloudXCore/CLXLogger.h>

// Use our wrapper to avoid Swift dependencies
#import "../RendererWrapper/CLXRendererWebView.h"

/**
 * Private interface for CLXRendererBanner
 * 
 * Contains internal properties for ad content, UI components,
 * and delegate management that should not be exposed publicly.
 */
@interface CLXRendererBanner () <CLXRendererWebViewDelegate>

@property (nonatomic, strong) NSString *adm;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, assign) BOOL hasClosedButton;
@property (nonatomic, strong) CLXRendererWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXRendererBanner

@synthesize delegate;
@synthesize timeout;

/**
 * Initialize CloudX Renderer Banner with ad markup and configuration
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
 * @return Initialized CLXRendererBanner instance
 */
- (instancetype)initWithAdm:(NSString *)adm
             hasClosedButton:(BOOL)hasClosedButton
                        type:(CLXBannerType)type
               viewController:(UIViewController *)viewController
                     delegate:(id<CLXAdapterBannerDelegate>)delegate {
    self.logger = [[CLXLogger alloc] initWithCategory:@"CloudXRendererBanner"];
    [self.logger debug:[NSString stringWithFormat:@"CloudXRendererBanner initialization - Markup: %lu chars, Type: %ld, CloseBtn: %@", (unsigned long)adm.length, (long)type, hasClosedButton ? @"YES" : @"NO"]];
    
    // Start performance tracking for initialization
    [[CLXPerformanceManager sharedManager] startLoadTimerForKey:[NSString stringWithFormat:@"banner_%p", self]];
    
    self = [super init];
    if (self) {
        // Configure core properties
        self.delegate = delegate;
        self.adm = adm;
        self.viewController = viewController;
        self.type = type;
        self.hasClosedButton = hasClosedButton;
        
        // Validate ad markup content
        if (!self.adm || self.adm.length == 0) {
            [self.logger error:@"Invalid ad markup - empty or nil"];
        }
        
        // Note: Close button creation deferred to load() to avoid dispatch_sync deadlocks
        
        [self.logger debug:[NSString stringWithFormat:@"CloudXRendererBanner initialization completed - Instance: %p", self]];
    } else {
        [self.logger error:@"Super init failed"];
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
 * Returns the current version of the CloudX Renderer SDK.
 * 
 * @return SDK version string
 */
- (NSString *)sdkVersion {
    return CLXRendererVersion;
}

/**
 * Load the banner ad into the WebView.
 * 
 * This method performs pre-load validation, calculates banner size,
 * creates the WebView, and loads the ad content.
 * It is typically called after initialization.
 */
- (void)load {
    [self.logger info:@"[ Banner load() method called"];
    
    // Pre-load validation
    if (!self.adm || self.adm.length == 0) {
        [self.logger error:@"Cannot load - ad markup is empty or nil"];
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            NSError *error = [NSError errorWithDomain:@"CloudXRendererBanner" code:400 userInfo:@{NSLocalizedDescriptionKey: @"Ad markup is empty or nil"}];
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    if (!self.viewController) {
        [self.logger error:@"Cannot load - view controller is nil"];
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            NSError *error = [NSError errorWithDomain:@"CloudXRendererBanner" code:401 userInfo:@{NSLocalizedDescriptionKey: @"View controller is nil"}];
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Start render timer
        [[CLXPerformanceManager sharedManager] startRenderTimerForKey:[NSString stringWithFormat:@"banner_%p", self]];
        
        CGSize bannerSize = [self getBannerSizeForType:self.type];
        [self.logger debug:[NSString stringWithFormat:@"Calculated banner size: %@", NSStringFromCGSize(bannerSize)]];
        
        if (bannerSize.width <= 0 || bannerSize.height <= 0) {
            [self.logger error:@"Invalid banner size calculated"];
            if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
                NSError *error = [NSError errorWithDomain:@"CloudXRendererBanner" code:402 userInfo:@{NSLocalizedDescriptionKey: @"Invalid banner size"}];
                [self.delegate failToLoadBanner:self error:error];
            }
            return;
        }
        
        CGRect frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        self.webView = [[CLXRendererWebView alloc] initWithFrame:frame placementType:CLXMRAIDPlacementTypeInline];
        
        if (self.webView) {
            [self.logger debug:[NSString stringWithFormat:@"CLXRendererWebView created successfully: %p", self.webView]];
            self.webView.delegate = self;
            self.webView.scrollView.scrollEnabled = NO;
            self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            // Configure advanced features
            self.webView.optimizeForPerformance = YES;
            self.webView.enableViewabilityTracking = YES;
            self.webView.preloadResources = YES;
            self.webView.viewabilityStandard = CLXViewabilityStandardIAB;
            
            // Generate optimized HTML with performance enhancements
            NSString *viewport = [NSString stringWithFormat:@"<meta name='viewport' content='width=%d, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>", (int)bannerSize.width];
            NSString *style = @"<style>"
                              @"html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }"
                              @"img { display: block; width: 100% !important; height: 100% !important; max-width: none !important; object-fit: fill; }"
                              @"* { box-sizing: border-box; }"
                              @"body > * { max-width: 100%; }"
                              @"</style>";
            
            // Use performance manager to optimize HTML
            CLXPerformanceManager *perfManager = [CLXPerformanceManager sharedManager];
            NSString *optimizedAdm = [perfManager optimizeHTMLContent:self.adm forSize:bannerSize];
            
            // Use original adm if optimization failed
            if (!optimizedAdm) {
                optimizedAdm = self.adm ?: @"";
            }
            
            NSString *htmlString = [NSString stringWithFormat:@"<!DOCTYPE html><html><head>%@%@</head><body>%@</body></html>", viewport, style, optimizedAdm];
            
            [self.logger debug:[NSString stringWithFormat:@"HTML generated - %lu chars", (unsigned long)htmlString.length]];
            
            // Check for video content
            BOOL hasVideo = [self.adm containsString:@"<video"] || [self.adm containsString:@"<VAST"] || [self.adm containsString:@".mp4"] || [self.adm containsString:@".webm"];
            if (hasVideo) {
                [self.logger info:@"📹 [LOAD] Video content detected"];
                self.webView.allowsInlineMediaPlayback = YES;
                self.webView.requiresUserActionForPlayback = NO;
            }
            
            // Check for MRAID content
            BOOL hasMRAID = [self.adm containsString:@"mraid"] || [self.adm containsString:@"expand"] || [self.adm containsString:@"resize"];
            if (hasMRAID) {
                [self.logger info:@"[LOAD] MRAID content detected"];
            }
            
            [self.logger debug:@"Loading HTML into CLXRendererWebView with advanced features enabled"];
            // Use CLXRendererWebView's loadOptimizedHTML method for best performance
            [self.webView loadOptimizedHTML:htmlString baseURL:nil completion:^(BOOL success, NSError *error) {
                if (success) {
                    [self.logger debug:@"HTML loaded successfully into webview"];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"Failed to load HTML: %@", error.localizedDescription]];
                }
            }];
            
            if (@available(iOS 16.4, *)) {
                self.webView.inspectable = YES;
            }
            
            if (self.hasClosedButton) {
                // Create close button on main thread (we're already on main thread via dispatch_async)
                if (!self.closeButton) {
                    self.closeButton = [UIButton buttonWithType:UIButtonTypeClose];
                    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
                }
                [self.closeButton addTarget:self action:@selector(closeBanner:) forControlEvents:UIControlEventTouchUpInside];
                [self.webView addSubview:self.closeButton];
                
                [NSLayoutConstraint activateConstraints:@[
                    [self.webView.trailingAnchor constraintEqualToAnchor:self.closeButton.trailingAnchor],
                    [self.webView.topAnchor constraintEqualToAnchor:self.closeButton.topAnchor]
                ]];
                [self.logger info:@"Close button added"];
            }
            
        } else {
            [self.logger error:@"Failed to create WKWebView"];
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
 * Handle impression event when viewability threshold is met.
 * 
 * This method is called by the viewability tracker when the banner has met
 * IAB viewability standards (50% visible for 1 second). It forwards the
 * impression event to the delegate for session metrics tracking.
 */
- (void)impression {
    [self.logger info:@"VIEWABILITY [ Banner met viewability threshold - firing impression"];
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.logger debug:@"Calling impressionBanner on delegate"];
        [self.delegate impressionBanner:self];
    }
}

/**
 * Destroy the banner ad and clean up resources.
 * 
 * Removes the WebView from its superview and invalidates its delegate.
 */
- (void)destroy {
    // WebView is a UIView - must be cleaned up on main thread
    CLXRendererWebView *viewToDestroy = self.webView;
    self.webView = nil;
    
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

#pragma mark - CLXRendererWebViewDelegate

@implementation CLXRendererBanner (CLXRendererWebViewDelegate)

/**
 * Get the view controller for presenting modals.
 * 
 * This method is required by CLXRendererWebViewDelegate to present modal
 * content like SafariViewController.
 * 
 * @return UIViewController for presenting modals.
 */
- (UIViewController *)viewControllerForPresentingModals {
    [self.logger debug:@"viewControllerForPresentingModals called"];
    return self.viewController;
}

/**
 * Notify when the WebView is ready to display the banner.
 * 
 * This method is called when the WebView has finished loading and is ready
 * to be displayed to the user. It ends performance timers and logs metrics.
 * 
 * @param webView The CLXRendererWebView that is ready.
 */
- (void)webViewReadyToDisplay:(CLXRendererWebView *)webView {
    [self.logger debug:@"webViewReadyToDisplay called - banner is ready!"];
    [self.logger debug:[NSString stringWithFormat:@"CLXRendererWebView: %p", webView]];
    [self.logger debug:[NSString stringWithFormat:@"Banner instance: %p", self]];
    [self.logger debug:[NSString stringWithFormat:@"Delegate available: %@", self.delegate ? @"YES" : @"NO"]];
    
    // End performance timers
    NSString *timerKey = [NSString stringWithFormat:@"banner_%p", self];
    [[CLXPerformanceManager sharedManager] endLoadTimerForKey:timerKey];
    [[CLXPerformanceManager sharedManager] endRenderTimerForKey:timerKey];
    
    // Log performance metrics
    CLXPerformanceMetrics *metrics = [[CLXPerformanceManager sharedManager] metrics];
    [self.logger debug:[NSString stringWithFormat:@"[PERFORMANCE] Load time: %.3f seconds", metrics.loadTime]];
    [self.logger debug:[NSString stringWithFormat:@"[PERFORMANCE] Render time: %.3f seconds", metrics.renderTime]];
    
    [self.logger debug:@"Notifying delegate: didLoadBanner..."];
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.logger debug:@"Calling didLoadBanner on delegate"];
        [self.delegate didLoadBanner:self];
        [self.logger debug:@"didLoadBanner call completed"];
    } else {
        [self.logger warn:@"[DELEGATE] Delegate does not respond to didLoadBanner"];
    }
    
    [self.logger info:@"SUCCESS [ Banner load sequence completed successfully"];
}

/**
 * Handle errors during WebView loading.
 * 
 * This method is called if the WebView fails to load the ad content.
 * It ends performance timers and logs the error.
 * 
 * @param webView The CLXRendererWebView that failed to load.
 * @param error The NSError describing the failure.
 */
- (void)webView:(CLXRendererWebView *)webView failedToLoadWithError:(NSError *)error {
    [self.logger error:@"Banner failed to load - webView error occurred"];
    [self.logger error:[NSString stringWithFormat:@"WebView: %p", webView]];
    [self.logger error:[NSString stringWithFormat:@"Banner instance: %p", self]];
    [self.logger error:[NSString stringWithFormat:@"Error domain: %@", error.domain]];
    [self.logger error:[NSString stringWithFormat:@"Error code: %ld", (long)error.code]];
    [self.logger error:[NSString stringWithFormat:@"Error description: %@", error.localizedDescription]];
    [self.logger error:[NSString stringWithFormat:@"Error failure reason: %@", error.localizedFailureReason ?: @"None"]];
    [self.logger error:[NSString stringWithFormat:@"Error user info: %@", error.userInfo]];
    
    // End performance timers on failure
    NSString *timerKey = [NSString stringWithFormat:@"banner_%p", self];
    [[CLXPerformanceManager sharedManager] endLoadTimerForKey:timerKey];
    [[CLXPerformanceManager sharedManager] endRenderTimerForKey:timerKey];
    
    // Log attempted ad markup for debugging
    if (self.adm && self.adm.length > 0) {
        [self.logger debug:[NSString stringWithFormat:@"Ad markup that failed to load: %@", 
                      [self.adm substringToIndex:MIN(300, self.adm.length)]]];
    } else {
        [self.logger error:@"Ad markup was empty or nil"];
    }
    
    [self.logger debug:@"Notifying delegate of failure..."];
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.logger error:@"📞 [DELEGATE] Calling failToLoadBanner:error: on delegate"];
        [self.delegate failToLoadBanner:self error:error];
        [self.logger debug:@"failToLoadBanner:error: call completed"];
    } else {
        [self.logger warn:@"[DELEGATE] Delegate does not respond to failToLoadBanner:error: - no error callback available"];
    }
    
    [self.logger error:@"🔚 [ERROR] Banner error handling completed"];
}

/**
 * Handle click-through link events.
 * 
 * This method is called when the user taps on a click-through link within
 * the WebView. It opens the URL in a SafariViewController.
 * 
 * @param webView The CLXRendererWebView that received the click.
 * @param url The NSURL of the click-through link.
 */
- (void)webView:(CLXRendererWebView *)webView receivedClickthroughLink:(NSURL *)url {
    [self.logger info:@"webView:receivedClickthroughLink called"];
    [self.logger debug:[NSString stringWithFormat:@"URL: %@", url]];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.logger info:@"Calling delegate clickBanner"];
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

// MRAID and rewarded events are handled internally by CLXRendererWebView

@end 