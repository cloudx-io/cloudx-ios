//
//  CloudXFullscreenStaticContainerViewController.m
//  CloudXPrebidAdapter
//
//  Fullscreen static container view controller for CloudX Prebid Adapter
//  
//  This class provides fullscreen ad display functionality including:
//  - Fullscreen WebView presentation for interstitial ads
//  - Close button management and positioning
//  - Safe area handling for modern devices
//  - SafariViewController integration for click-through links
//  - Comprehensive event delegation
//  - Memory management and cleanup
//  - MRAID 3.0 support with JavaScript API injection
//  - Viewability tracking with IAB compliance
//  - Performance monitoring and optimization
//

#import "CLXFullscreenStaticContainerViewController.h"
#import "CLXWKScriptHelper.h"
#import "CLXMRAIDManager.h"
#import "CLXViewabilityTracker.h"
#import "CLXPerformanceManager.h"
#import <SafariServices/SafariServices.h>
#import <CloudXCore/CLXLogger.h>

/**
 * Private interface for CLXFullscreenStaticContainerViewController
 * 
 * Contains internal properties for WebView management, UI components,
 * and delegate handling that should not be exposed publicly.
 */
@interface CLXFullscreenStaticContainerViewController () <WKNavigationDelegate, WKUIDelegate, CLXMRAIDManagerDelegate, CLXViewabilityTrackerDelegate>

@property (nonatomic, weak) id<CLXFullscreenStaticContainerViewControllerDelegate> delegate;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSString *adm;
@property (nonatomic, assign) CGFloat topConstant;
@property (nonatomic, assign) CGFloat trailingConstant;
@property (nonatomic, strong) CLXLogger *logger;

// MRAID 3.0 Support
@property (nonatomic, strong) CLXMRAIDManager *mraidManager;

// Viewability Tracking
@property (nonatomic, strong) CLXViewabilityTracker *viewabilityTracker;

// Performance Management
@property (nonatomic, strong) CLXPerformanceManager *performanceManager;
@property (nonatomic, strong) NSString *loadTimerKey;

@end

@implementation CLXFullscreenStaticContainerViewController

/**
 * Initialize fullscreen container with delegate and ad markup
 * 
 * Sets up a fullscreen view controller for displaying interstitial ads.
 * Configures WebView, close button, and modal presentation style.
 * Integrates MRAID 3.0, viewability tracking, and performance monitoring.
 * 
 * @param delegate Delegate for handling fullscreen events
 * @param adm Ad markup string (HTML/JavaScript content)
 * @return Initialized CLXFullscreenStaticContainerViewController instance
 */
- (instancetype)initWithDelegate:(id<CLXFullscreenStaticContainerViewControllerDelegate>)delegate
                            adm:(NSString *)adm {
    self.logger = [[CLXLogger alloc] initWithCategory:@"CLXFullscreenStaticContainerViewController"];
    [self.logger info:[NSString stringWithFormat:@"🚀 [INIT] CLXFullscreenStaticContainerViewController initialization started - Delegate: %@, Ad markup: %lu chars", delegate ? @"Present" : @"nil", (unsigned long)(adm ? adm.length : 0)]];
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self.logger info:@"✅ [INIT] Super init successful"];
        
        // Configure core properties
        self.delegate = delegate;
        self.adm = adm;
        self.topConstant = 12.0;
        self.trailingConstant = 12.0;
        
        // Initialize performance manager
        self.performanceManager = [CLXPerformanceManager sharedManager];
        [self.logger info:@"✅ [INIT] Performance manager initialized"];
        
        // Viewability tracker will be initialized in viewDidLoad when self.view is available
        
        // Create WebView with fullscreen configuration
        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero 
                                          configuration:[CLXWKScriptHelper shared].fullscreenConfiguration];
        self.webView.UIDelegate = self;
        self.webView.navigationDelegate = self;
        
        // Set modal presentation style for fullscreen display
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self setupUI];
        [self.logger info:@"🎯 [INIT] CLXFullscreenStaticContainerViewController initialization completed successfully - UI setup completed"];
    } else {
        [self.logger error:@"❌ [INIT] Super init failed"];
    }
    return self;
}

/**
 * View lifecycle method - called when view loads
 * Initializes viewability tracker when view is available
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.logger debug:@"📱 [LIFECYCLE] viewDidLoad called"];
    
    // Initialize viewability tracker now that self.view is available
    self.viewabilityTracker = [[CLXViewabilityTracker alloc] initWithView:self.view];
    self.viewabilityTracker.delegate = self;
    [self.logger info:@"✅ [INIT] Viewability tracker initialized"];
}

/**
 * View lifecycle method - called when view appears
 * Starts viewability tracking and MRAID initialization
 */
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.logger debug:@"📱 [LIFECYCLE] viewDidAppear called"];
    
    // Start viewability tracking with IAB standard configuration
    [self startViewabilityTracking];
    
    // Initialize MRAID manager but don't inject JavaScript yet
    // JavaScript will be injected in webViewDidFinishLoad when WebView is ready
    self.mraidManager = [[CLXMRAIDManager alloc] initWithWebView:self.webView 
                                                   placementType:CLXMRAIDPlacementTypeInterstitial];
    
    // Start performance monitoring
    [self.performanceManager startRenderTimerForKey:[NSString stringWithFormat:@"interstitial_render_%p", self]];
}

/**
 * View lifecycle method - called when view disappears
 * Stops viewability tracking and cleans up resources
 */
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.logger debug:@"📱 [LIFECYCLE] viewDidDisappear called"];
    
    // Stop viewability tracking
    [self stopViewabilityTracking];
}

#pragma mark - Public Methods

/**
 * Destroy the fullscreen container and clean up resources
 * 
 * Removes WebView from superview and invalidates delegates
 * to prevent memory leaks. Performs cleanup on main queue.
 * Also cleans up MRAID manager and viewability tracker.
 */
- (void)destroy {
    [self.logger info:@"🗑️ [DESTROY] Destroying fullscreen container"];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Stop viewability tracking
        [self stopViewabilityTracking];
        
        // Clean up MRAID manager
        [self.mraidManager cleanup];
        self.mraidManager = nil;
        
        // Clean up WebView
        [self.webView removeFromSuperview];
        self.webView.navigationDelegate = nil;
        self.webView.UIDelegate = nil;
        
        [self.logger info:@"✅ [DESTROY] Fullscreen container destroyed successfully"];
    });
}

/**
 * Load HTML content into the WebView
 * 
 * Loads the ad markup into the WebView for display.
 * Performs validation to ensure ad markup is not empty.
 * Executes on main queue for UI safety.
 * Starts performance monitoring for load time measurement.
 */
- (void)loadHTML {
    [self.logger info:@"🌐 [LOAD] Loading HTML content"];
    
    // Start performance monitoring
    self.loadTimerKey = [NSString stringWithFormat:@"interstitial_load_%p", self];
    [self.performanceManager startLoadTimerForKey:self.loadTimerKey];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.adm && self.adm.length > 0) {
            // Optimize HTML content for better performance
            NSString *optimizedHTML = [self.performanceManager optimizeHTMLContent:self.adm 
                                                                           forSize:self.view.bounds.size];
            
            if (optimizedHTML) {
                [self.webView loadHTMLString:optimizedHTML baseURL:nil];
                [self.logger info:@"✅ [LOAD] Optimized HTML content loaded successfully"];
            } else {
                [self.webView loadHTMLString:self.adm baseURL:nil];
                [self.logger info:@"✅ [LOAD] Original HTML content loaded successfully"];
            }
        } else {
            [self.logger info:@"⚠️ [LOAD] Cannot load - adm is nil or empty"];
        }
    });
}

#pragma mark - Private Methods

/**
 * Set up the user interface components
 * 
 * Creates and configures the close button with proper styling
 * and positioning. Sets up Auto Layout constraints for
 * responsive layout across different device sizes.
 */
- (void)setupUI {
    [self.logger debug:@"🔧 [SETUP] Setting up UI components"];
    
    // Create close button with system styling
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton addTarget:self action:@selector(clickClose) forControlEvents:UIControlEventTouchUpInside];
    
    // Configure close button image
    UIImage *image = [UIImage systemImageNamed:@"xmark.circle" 
                            withConfiguration:[UIImageSymbolConfiguration configurationWithFont:[UIFont systemFontOfSize:14] 
                                                                                         scale:UIImageSymbolScaleLarge]];
    [self.closeButton setImage:image forState:UIControlStateNormal];
    
    // Configure Auto Layout
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add views to hierarchy
    [self.view addSubview:self.webView];
    [self.view addSubview:self.closeButton];
    
    // Set up constraints for responsive layout
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [self.closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:self.topConstant],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-self.trailingConstant]
    ]];
    
    [self.logger info:@"✅ [SETUP] UI components configured successfully"];
}

/**
 * Initialize MRAID 3.0 manager for rich media support
 * 
 * Creates MRAID manager with interstitial placement type
 * and sets up delegate for handling MRAID events.
 */
- (void)initializeMRAIDManager {
    [self.logger info:@"🔧 [MRAID] Initializing MRAID 3.0 manager"];
    
    self.mraidManager = [[CLXMRAIDManager alloc] initWithWebView:self.webView 
                                                   placementType:CLXMRAIDPlacementTypeInterstitial];
    self.mraidManager.delegate = self;
    
    [self.logger info:@"✅ [MRAID] MRAID 3.0 manager initialized successfully"];
}

/**
 * Start viewability tracking for IAB compliance
 * 
 * Creates viewability tracker with IAB standard configuration
 * and starts 60 FPS measurement tracking.
 */
- (void)startViewabilityTracking {
    [self.logger info:@"👁️ [VIEWABILITY] Starting viewability tracking"];
    
    // Configure IAB standard (50% visible for 1 second)
    [self.viewabilityTracker configureCustomStandard:0.5 timeRequirement:1.0];
    
    // Start tracking
    [self.viewabilityTracker startTracking];
    
    [self.logger info:@"✅ [VIEWABILITY] Viewability tracking started successfully"];
}

/**
 * Stop viewability tracking and clean up resources
 * 
 * Stops the viewability tracker and releases resources.
 */
- (void)stopViewabilityTracking {
    if (self.viewabilityTracker) {
        [self.logger info:@"⏹️ [VIEWABILITY] Stopping viewability tracking"];
        [self.viewabilityTracker stopTracking];
        self.viewabilityTracker = nil;
        [self.logger info:@"✅ [VIEWABILITY] Viewability tracking stopped"];
    }
}

/**
 * Handle close button tap
 * 
 * Dismisses the fullscreen container and notifies the delegate
 * of the close action. Ensures proper cleanup of resources.
 */
- (void)clickClose {
    [self.logger info:@"❌ [CLOSE] Close button tapped"];
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(closeFullScreenAd)]) {
            [self.logger debug:@"📞 [DELEGATE] Calling closeFullScreenAd on delegate"];
            [self.delegate closeFullScreenAd];
        } else {
            [self.logger info:@"⚠️ [DELEGATE] Delegate does not respond to closeFullScreenAd"];
        }
    }];
}

@end

#pragma mark - WKNavigationDelegate

/**
 * WKNavigationDelegate implementation for WebView navigation handling
 */
@implementation CLXFullscreenStaticContainerViewController (WKNavigationDelegate)

/**
 * Handle successful WebView navigation completion
 * 
 * Called when the WebView finishes loading content.
 * Notifies the delegate that the ad has loaded successfully.
 * Ends performance monitoring and records load time.
 * 
 * @param webView The WKWebView that finished navigation
 * @param navigation The WKNavigation object
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.logger info:@"✅ [NAVIGATION] WebView navigation completed successfully"];
    
    // Now that WebView has loaded HTML content, inject MRAID JavaScript
    if (self.mraidManager) {
        [self.logger debug:@"🔧 [MRAID] Injecting JavaScript after WebView load completion"];
        NSString *mraidJavaScript = [self.mraidManager getMRAIDJavaScript];
        [webView evaluateJavaScript:mraidJavaScript completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"❌ [MRAID] JavaScript injection failed: %@", error]];
            } else {
                [self.logger info:@"✅ [MRAID] JavaScript injected successfully"];
            }
        }];
    }
    
    // End performance monitoring
    if (self.loadTimerKey) {
        [self.performanceManager endLoadTimerForKey:self.loadTimerKey];
        [self.logger info:@"📊 [PERFORMANCE] Load time measurement completed"];
    }
    
    // Start render timer
    NSString *renderTimerKey = [NSString stringWithFormat:@"interstitial_render_%p", self];
    [self.performanceManager startRenderTimerForKey:renderTimerKey];
    
    // End render timer after a short delay to measure render time
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.performanceManager endRenderTimerForKey:renderTimerKey];
        [self.logger info:@"📊 [PERFORMANCE] Render time measurement completed"];
    });
    
    if ([self.delegate respondsToSelector:@selector(didLoad)]) {
        [self.logger debug:@"📞 [DELEGATE] Calling didLoad on delegate"];
        [self.delegate didLoad];
    } else {
        [self.logger info:@"⚠️ [DELEGATE] Delegate does not respond to didLoad"];
    }
}

/**
 * Handle WebView navigation failure
 * 
 * Called when the WebView fails to load content.
 * Notifies the delegate of the failure with error details.
 * Ends performance monitoring on failure.
 * 
 * @param webView The WKWebView that failed navigation
 * @param navigation The WKNavigation object
 * @param error The NSError describing the failure
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"❌ [NAVIGATION] WebView navigation failed: %@", error.localizedDescription]];
    
    // End performance monitoring on failure
    if (self.loadTimerKey) {
        [self.performanceManager endLoadTimerForKey:self.loadTimerKey];
    }
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithError:)]) {
        [self.logger debug:@"📞 [DELEGATE] Calling didFailToShowWithError on delegate"];
        [self.delegate didFailToShowWithError:error];
    } else {
        [self.logger info:@"⚠️ [DELEGATE] Delegate does not respond to didFailToShowWithError"];
    }
}

@end

#pragma mark - WKUIDelegate

/**
 * WKUIDelegate implementation for WebView UI handling
 */
@implementation CLXFullscreenStaticContainerViewController (WKUIDelegate)

/**
 * Handle WebView popup window creation for click-through links
 * 
 * Creates SafariViewController for external link handling.
 * Notifies delegate of click events for tracking.
 * 
 * @param webView The WKWebView requesting the new window
 * @param configuration The WKWebViewConfiguration for the new window
 * @param navigationAction The WKNavigationAction that triggered the request
 * @param windowFeatures The WKWindowFeatures for the new window
 * @return nil to prevent new window creation, handle in SafariViewController
 */
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (navigationAction.targetFrame == nil) {
        [self.logger info:@"🔗 [CLICK] Handling click-through link"];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = navigationAction.request.URL;
            if (url) {
                [self.logger debug:[NSString stringWithFormat:@"📊 [CLICK] URL: %@", url]];
                
                if ([self.delegate respondsToSelector:@selector(didClickFullAdd)]) {
                    [self.logger debug:@"📞 [DELEGATE] Calling didClickFullAdd on delegate"];
                    [self.delegate didClickFullAdd];
                } else {
                    [self.logger info:@"⚠️ [DELEGATE] Delegate does not respond to didClickFullAdd"];
                }
                
                // Open URL in SafariViewController for better user experience
                SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
                config.entersReaderIfAvailable = YES;
                
                SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url configuration:config];
                [self presentViewController:safariVC animated:YES completion:^{
                    [self.logger info:@"✅ [CLICK] SafariViewController presented successfully"];
                }];
            } else {
                [self.logger info:@"⚠️ [CLICK] URL is nil, cannot open SafariViewController"];
            }
        });
    }
    return nil;
}

@end

#pragma mark - CLXMRAIDManagerDelegate

/**
 * MRAID manager delegate implementation for rich media events
 */
@implementation CLXFullscreenStaticContainerViewController (CLXMRAIDManagerDelegate)

- (void)mraidManager:(CLXMRAIDManager *)manager didChangeState:(CLXMRAIDState)state {
    [self.logger info:[NSString stringWithFormat:@"📱 [MRAID] State changed to: %ld", (long)state]];
}

- (void)mraidManager:(CLXMRAIDManager *)manager didChangeViewable:(BOOL)viewable {
    [self.logger info:[NSString stringWithFormat:@"👁️ [MRAID] Viewability changed to: %@", viewable ? @"YES" : @"NO"]];
}

- (void)mraidManager:(CLXMRAIDManager *)manager didReceiveCloseRequest:(NSDictionary *)parameters {
    [self.logger info:@"❌ [MRAID] Close request received from MRAID"];
    [self clickClose];
}

- (void)mraidManager:(CLXMRAIDManager *)manager didRequestOpenURL:(NSURL *)url {
    [self.logger info:[NSString stringWithFormat:@"🔗 [MRAID] Open URL request: %@", url]];
    
    if ([self.delegate respondsToSelector:@selector(didClickFullAdd)]) {
        [self.delegate didClickFullAdd];
    }
    
    SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
    config.entersReaderIfAvailable = YES;
    
    SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url configuration:config];
    [self presentViewController:safariVC animated:YES completion:nil];
}

@end

#pragma mark - CLXViewabilityTrackerDelegate

/**
 * Viewability tracker delegate implementation for IAB compliance
 */
@implementation CLXFullscreenStaticContainerViewController (CLXViewabilityTrackerDelegate)

- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didChangeViewability:(BOOL)viewable measurement:(CLXViewabilityMeasurement *)measurement {
    [self.logger info:[NSString stringWithFormat:@"👁️ [VIEWABILITY] Viewability changed to: %@ (%.1f%% exposed)", 
                       viewable ? @"YES" : @"NO", measurement.exposedPercentage * 100]];
    
    // Update MRAID viewability state
    [self.mraidManager updateViewability:viewable];
}

- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didUpdateExposure:(CLXViewabilityMeasurement *)measurement {
    // Update MRAID exposure data
    [self.mraidManager updateExposure:measurement.exposedPercentage 
                           exposedRect:measurement.exposedRect];
}

- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didMeetViewabilityThreshold:(CLXViewabilityMeasurement *)measurement {
    [self.logger info:@"🎯 [VIEWABILITY] IAB viewability threshold met!"];
    [self.logger info:[NSString stringWithFormat:@"📊 [VIEWABILITY] Viewable time: %.2f seconds", measurement.viewableTime]];
    
    // Trigger impression when viewability threshold is met
    if ([self.delegate respondsToSelector:@selector(impression)]) {
        [self.delegate impression];
    }
}

@end 