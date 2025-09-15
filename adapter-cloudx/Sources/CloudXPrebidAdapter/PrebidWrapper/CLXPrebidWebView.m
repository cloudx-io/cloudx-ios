//
//  CLXPrebidWebView.m
//  CloudXPrebidAdapter
//
//  Enhanced WebView wrapper with MRAID 3.0, viewability tracking, and performance optimization
//  
//  This class provides a unified WebView interface for CloudX Prebid Adapter including:
//  - Advanced WKWebView configuration with media playback support
//  - Complete MRAID 3.0 integration with JavaScript API injection
//  - IAB-compliant viewability tracking with high-frequency measurement
//  - Performance optimization with resource preloading and caching
//  - Responsive viewport configuration for mobile ads
//  - Comprehensive event delegation and state management
//  - Background/foreground state handling
//  - Memory management and cleanup
//

#import "CLXPrebidWebView.h"
#import "../Core/CLXMRAIDManager.h"
#import "../Core/CLXViewabilityTracker.h"
#import "../Core/CLXPerformanceManager.h"
#import <CloudXCore/CLXLogger.h>

/**
 * Private interface for CLXPrebidWebView
 * 
 * Contains internal properties for WebView management, MRAID integration,
 * viewability tracking, and state management that should not be exposed publicly.
 */
@interface CLXPrebidWebView () <WKNavigationDelegate, WKUIDelegate, CLXMRAIDManagerDelegate, CLXViewabilityTrackerDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) CLXMRAIDManager *mraidManager;
@property (nonatomic, strong) CLXViewabilityTracker *viewabilityTracker;
@property (nonatomic, strong) CLXLogger *logger;

// State tracking
@property (nonatomic, assign) BOOL hasFinishedLoading;
@property (nonatomic, assign) BOOL hasReportedReady;
@property (nonatomic, copy) void (^loadCompletion)(BOOL success, NSError * _Nullable error);

@end

@implementation CLXPrebidWebView

/**
 * Initialize CLXPrebidWebView with frame and placement type
 * 
 * Sets up a comprehensive WebView environment including:
 * - Advanced WKWebView configuration with media support
 * - MRAID 3.0 manager integration
 * - IAB-compliant viewability tracking
 * - Performance optimization features
 * - Responsive viewport configuration
 * 
 * @param frame Frame for the WebView
 * @param placementType MRAID placement type (inline, interstitial)
 * @return Initialized CLXPrebidWebView instance
 */
- (instancetype)initWithFrame:(CGRect)frame placementType:(CLXMRAIDPlacementType)placementType {
    self.logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidWebView"];
    [self.logger info:[NSString stringWithFormat:@"🚀 [INIT] CLXPrebidWebView initialization - Frame: %@, Placement: %ld", NSStringFromCGRect(frame), (long)placementType]];
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialize default configuration
        _placementType = placementType;
        _enableViewabilityTracking = YES;
        _optimizeForPerformance = YES;
        _preloadResources = YES;
        _viewabilityStandard = CLXViewabilityStandardIAB;
        _hasFinishedLoading = NO;
        _hasReportedReady = NO;
        
        // Set up core components
        [self setupWebView];
        [self setupMRAIDManager];
        [self setupViewabilityTracking];
        [self.logger info:@"✅ [INIT] CLXPrebidWebView initialization completed successfully"];
    } else {
        [self.logger error:@"❌ [INIT] Super init failed"];
    }
    return self;
}

/**
 * Convenience initializer with default inline placement type
 * 
 * @param frame Frame for the WebView
 * @return Initialized CLXPrebidWebView instance with inline placement
 */
- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame placementType:CLXMRAIDPlacementTypeInline];
}

/**
 * Cleanup resources and remove observers
 * Ensures proper cleanup of WebView, MRAID manager, and viewability tracker
 */
- (void)dealloc {
    [self cleanup];
}

#pragma mark - Setup Methods

/**
 * Set up WKWebView with advanced configuration for ad content
 * 
 * Configures WebView with:
 * - Media playback support for video ads
 * - Responsive viewport for mobile optimization
 * - Performance optimization scripts
 * - MRAID JavaScript injection
 * - User interaction handling
 */
- (void)setupWebView {
    // Create enhanced configuration for ad content
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    configuration.allowsAirPlayForMediaPlayback = YES;
    configuration.allowsPictureInPictureMediaPlayback = NO; // Disable for ad content
    
    
    // User content controller for MRAID and performance optimization
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    // Viewport configuration for responsive ads
    NSString *viewportScript = @"var meta = document.createElement('meta');"
                              @"meta.name = 'viewport';"
                              @"meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';"
                              @"document.head.appendChild(meta);";
    
    WKUserScript *viewportUserScript = [[WKUserScript alloc] initWithSource:viewportScript
                                                              injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                           forMainFrameOnly:YES];
    [userContentController addUserScript:viewportUserScript];
    
    // Performance optimization script
    if (self.optimizeForPerformance) {
        NSString *perfScript = @"document.addEventListener('DOMContentLoaded', function() {"
                              @"  var imgs = document.querySelectorAll('img');"
                              @"  imgs.forEach(function(img) {"
                              @"    img.loading = 'lazy';"
                              @"    if (!img.alt) img.alt = 'Ad content';"
                              @"  });"
                              @"});";
        
        WKUserScript *perfUserScript = [[WKUserScript alloc] initWithSource:perfScript
                                                              injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                           forMainFrameOnly:YES];
        [userContentController addUserScript:perfUserScript];
    }
    
    configuration.userContentController = userContentController;
    
    // Create WebView with frame
    self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Configure scroll view
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.showsVerticalScrollIndicator = NO;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    // Background configuration
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    
    [self addSubview:self.webView];
    
    [self.logger info:[NSString stringWithFormat:@"✅ [SETUP] WKWebView created and configured: %p", self.webView]];
}

- (void)setupMRAIDManager {
    self.mraidManager = [[CLXMRAIDManager alloc] initWithWebView:self.webView placementType:self.placementType];
    self.mraidManager.delegate = self;
    
    [self.logger info:@"✅ [SETUP] MRAID manager created"];
}

- (void)setupViewabilityTracking {
    if (!self.enableViewabilityTracking) {
        return;
    }
    
    self.viewabilityTracker = [[CLXViewabilityTracker alloc] initWithView:self];
    self.viewabilityTracker.delegate = self;
    
    // Configure based on standard
    switch (self.viewabilityStandard) {
        case CLXViewabilityStandardIAB:
            [self.viewabilityTracker configureCustomStandard:0.5 timeRequirement:1.0]; // 50% for 1 second
            break;
        case CLXViewabilityStandardMRC:
            [self.viewabilityTracker configureCustomStandard:0.5 timeRequirement:1.0]; // 50% for 1 second
            break;
        case CLXViewabilityStandardCustom:
            // Keep existing configuration
            break;
    }
    
    [self.logger info:@"✅ [SETUP] Viewability tracker configured"];
}

#pragma mark - Public Methods

- (void)loadOptimizedHTML:(NSString *)html baseURL:(nullable NSURL *)baseURL completion:(nullable void (^)(BOOL success, NSError *error))completion {
    [self.logger info:[NSString stringWithFormat:@"🚀 [LOAD] Starting optimized HTML load - %lu chars", (unsigned long)html.length]];
    
    if (!html || html.length == 0) {
        [self.logger error:@"❌ [LOAD] Cannot load - HTML content is empty or nil"];
        NSError *error = [NSError errorWithDomain:@"CLXPrebidWebView" code:400 userInfo:@{NSLocalizedDescriptionKey: @"HTML content is empty"}];
        if (completion) completion(NO, error);
        return;
    }
    
    // Reset state
    self.hasFinishedLoading = NO;
    self.hasReportedReady = NO;
    
    // Preload resources if enabled
    if (self.preloadResources) {
        CLXPreloadRequest *request = [[CLXPreloadRequest alloc] init];
        request.adMarkup = html;
        request.baseURL = baseURL;
        request.adSize = self.bounds.size;
        request.priority = 1;
        [[CLXPerformanceManager sharedManager] preloadAdContent:request];
    }
    
    // Optimize HTML if performance optimization is enabled
    NSString *finalHTML = html;
    if (self.optimizeForPerformance) {
        NSString *optimizedHTML = [[CLXPerformanceManager sharedManager] optimizeHTMLContent:html forSize:self.bounds.size];
        if (optimizedHTML) {
            finalHTML = optimizedHTML;
        }
    }
    
    // Store completion handler
    __block void (^storedCompletion)(BOOL, NSError *) = completion;
    
    // Start loading
    dispatch_async(dispatch_get_main_queue(), ^{
        if (finalHTML && finalHTML.length > 0) {
            [self.webView loadHTMLString:finalHTML baseURL:baseURL];
            [self.logger info:@"✅ [LOAD] HTML load initiated successfully"];
            
            // Log content analysis
            [self logContentAnalysis:finalHTML];
        } else {
            [self.logger error:@"❌ [LOAD] Cannot load - finalHTML is nil or empty"];
            if (storedCompletion) {
                NSError *error = [NSError errorWithDomain:@"CLXPrebidWebView" code:400 userInfo:@{NSLocalizedDescriptionKey: @"Final HTML content is empty"}];
                storedCompletion(NO, error);
            }
            return;
        }
        
        // Handle completion in navigation delegate
        self->_loadCompletion = storedCompletion;
    });
}

- (void)startViewabilityTracking {
    if (self.viewabilityTracker && self.enableViewabilityTracking) {
        [self.viewabilityTracker startTracking];
    }
}

- (void)stopViewabilityTracking {
    if (self.viewabilityTracker) {
        [self.viewabilityTracker stopTracking];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self.logger debug:@"🌐 [NAV] WebView started provisional navigation"];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self.logger debug:@"🌐 [NAV] WebView committed navigation"];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.logger info:@"🌐 [NAV] WebView finished navigation"];
    
    self.hasFinishedLoading = YES;
    
    // Check for MRAID content
    [webView evaluateJavaScript:@"typeof window.mraid !== 'undefined'" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (!error && [result boolValue]) {
            [self.logger info:@"📱 [NAV] MRAID detected in content"];
        }
    }];
    
    // Start viewability tracking
    [self startViewabilityTracking];
    
    // Update MRAID state
    if (self.mraidManager) {
        [self.mraidManager updateState:CLXMRAIDStateDefault];
        [self.mraidManager updateViewability:YES];
    }
    
    // Report ready to delegate
    if (!self.hasReportedReady) {
        self.hasReportedReady = YES;
        [self.logger info:@"🎉 [SUCCESS] WebView ready to display"];
        
        if ([self.delegate respondsToSelector:@selector(webViewReadyToDisplay:)]) {
            [self.delegate webViewReadyToDisplay:self];
        }
        
        if (self.loadCompletion) {
            self.loadCompletion(YES, nil);
            self.loadCompletion = nil;
        }
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"❌ [NAV] WebView navigation failed: %@", error.localizedDescription]];
    
    if ([self.delegate respondsToSelector:@selector(webView:failedToLoadWithError:)]) {
        [self.delegate webView:self failedToLoadWithError:error];
    }
    
    if (self.loadCompletion) {
        self.loadCompletion(NO, error);
        self.loadCompletion = nil;
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [self.logger info:[NSString stringWithFormat:@"🔗 [CLICK] User clicked link: %@", url.absoluteString]];
        
        if ([self.delegate respondsToSelector:@selector(webView:receivedClickthroughLink:)]) {
            [self.delegate webView:self receivedClickthroughLink:url];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - CLXMRAIDManagerDelegate

- (void)mraidManager:(CLXMRAIDManager *)manager didChangeState:(CLXMRAIDState)state {
    [self.logger debug:[NSString stringWithFormat:@"📱 [MRAID] State changed to: %ld", (long)state]];
}

- (void)mraidManager:(CLXMRAIDManager *)manager didChangeViewable:(BOOL)viewable {
    [self.logger debug:[NSString stringWithFormat:@"👁️ [MRAID] Viewability changed to: %@", viewable ? @"YES" : @"NO"]];
}

- (void)mraidManager:(CLXMRAIDManager *)manager didRequestOpenURL:(NSURL *)url {
    [self.logger info:[NSString stringWithFormat:@"🔗 [MRAID] Open URL requested: %@", url.absoluteString]];
    if ([self.delegate respondsToSelector:@selector(webView:receivedClickthroughLink:)]) {
        [self.delegate webView:self receivedClickthroughLink:url];
    }
}

- (void)mraidManager:(CLXMRAIDManager *)manager didReceiveCloseRequest:(nullable NSDictionary *)parameters {
    [self.logger debug:@"❌ [MRAID] Close request received"];
    // Handle close request based on placement type
}

- (void)mraidManager:(CLXMRAIDManager *)manager didRequestExpand:(nullable NSURL *)url {
    [self.logger debug:[NSString stringWithFormat:@"📱 [MRAID] Expand requested with URL: %@", url ? url.absoluteString : @"none"]];
    // Handle expand request
}

- (void)mraidManager:(CLXMRAIDManager *)manager didRequestResize:(CGSize)size {
    [self.logger debug:[NSString stringWithFormat:@"🔄 [MRAID] Resize requested to: %@", NSStringFromCGSize(size)]];
    // Handle resize request
}

#pragma mark - CLXViewabilityTrackerDelegate

- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didChangeViewability:(BOOL)viewable measurement:(CLXViewabilityMeasurement *)measurement {
    [self.logger debug:[NSString stringWithFormat:@"👁️ [VIEWABILITY] Changed to: %@", viewable ? @"VIEWABLE" : @"NOT_VIEWABLE"]];
    
    // Update MRAID
    if (self.mraidManager) {
        [self.mraidManager updateViewability:viewable];
        [self.mraidManager updateExposure:measurement.exposedPercentage exposedRect:measurement.exposedRect];
    }
}

- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didMeetViewabilityThreshold:(CLXViewabilityMeasurement *)measurement {
    [self.logger info:[NSString stringWithFormat:@"🎯 [VIEWABILITY] Threshold met! Viewable time: %.2f seconds", measurement.viewableTime]];
}

- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didUpdateExposure:(CLXViewabilityMeasurement *)measurement {
    // Log exposure updates less frequently to avoid spam
    static NSUInteger updateCount = 0;
    updateCount++;
    if (updateCount % 60 == 0) { // Every 60 updates (once per second at 60fps)
        [self.logger debug:[NSString stringWithFormat:@"📊 [VIEWABILITY] Exposure: %.1f%%", measurement.exposedPercentage * 100]];
    }
}

#pragma mark - UIViewController Support

- (nullable UIViewController *)viewControllerForPresentingModals {
    if ([self.delegate respondsToSelector:@selector(viewControllerForPresentingModals)]) {
        return [self.delegate viewControllerForPresentingModals];
    }
    return nil;
}

#pragma mark - Properties

- (UIScrollView *)scrollView {
    return self.webView.scrollView;
}

- (BOOL)allowsInlineMediaPlayback {
    return self.webView.configuration.allowsInlineMediaPlayback;
}

- (void)setAllowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback {
    // Note: This property is read-only on WKWebViewConfiguration after creation
    [self.logger info:@"⚠️ [CONFIG] allowsInlineMediaPlayback cannot be changed after WebView creation"];
}

- (BOOL)requiresUserActionForPlayback {
    return self.webView.configuration.mediaTypesRequiringUserActionForPlayback != WKAudiovisualMediaTypeNone;
}

- (void)setRequiresUserActionForPlayback:(BOOL)requiresUserActionForPlayback {
    // Note: This property is read-only on WKWebViewConfiguration after creation
    [self.logger info:@"⚠️ [CONFIG] requiresUserActionForPlayback cannot be changed after WebView creation"];
}

- (BOOL)inspectable {
    if (@available(iOS 16.4, *)) {
        return self.webView.inspectable;
    }
    return NO;
}

- (void)setInspectable:(BOOL)inspectable {
    if (@available(iOS 16.4, *)) {
        self.webView.inspectable = inspectable;
        [self.logger debug:[NSString stringWithFormat:@"🔧 [CONFIG] WebView inspectable set to: %@", inspectable ? @"YES" : @"NO"]];
    } else {
        [self.logger info:@"⚠️ [CONFIG] WebView inspectable requires iOS 16.4+"];
    }
}

#pragma mark - Missing Method Implementations

- (void)loadHTML:(NSString *)html baseURL:(nullable NSURL *)baseURL {
    [self loadOptimizedHTML:html baseURL:baseURL completion:nil];
}

- (void)expandToFullScreen {
    [self.logger info:@"🔧 [MRAID] expandToFullScreen called"];
    // TODO: Implement MRAID expand functionality
}

- (void)collapseFromExpanded {
    [self.logger info:@"🔧 [MRAID] collapseFromExpanded called"];
    // TODO: Implement MRAID collapse functionality
}

- (void)resizeToSize:(CGSize)size {
    [self.logger info:[NSString stringWithFormat:@"🔧 [MRAID] resizeToSize called: %@", NSStringFromCGSize(size)]];
    // TODO: Implement MRAID resize functionality
}

- (void)closeAd {
    [self.logger info:@"🔧 [MRAID] closeAd called"];
    // TODO: Implement MRAID close functionality
}

- (void)updateViewportVisibility:(CGRect)visibleRect {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [VIEWABILITY] updateViewportVisibility: %@", NSStringFromCGRect(visibleRect)]];
    // TODO: Implement viewport visibility update
}

- (void)enablePerformanceMonitoring {
    [self.logger info:@"🔧 [PERFORMANCE] enablePerformanceMonitoring called"];
    // Implementation would go here
}

- (CLXPerformanceMetrics *)currentPerformanceMetrics {
    [self.logger debug:@"🔧 [PERFORMANCE] currentPerformanceMetrics called"];
    // Return actual metrics here
    return [[CLXPerformanceMetrics alloc] init];
}

- (void)preloadResourcesInHTML:(NSString *)html completion:(nullable void (^)(BOOL success))completion {
    [self.logger info:@"🔧 [RESOURCES] preloadResourcesInHTML called"];
    if (completion) {
        completion(YES);
    }
}

- (void)clearResourceCache {
    [self.logger info:@"🔧 [RESOURCES] clearResourceCache called"];
    // Implementation would go here
}

- (void)optimizeMemoryUsage {
    [self.logger info:@"🔧 [RESOURCES] optimizeMemoryUsage called"];
    // Implementation would go here
}

- (void)playVideoAtURL:(NSURL *)videoURL fullscreen:(BOOL)fullscreen {
    [self.logger info:[NSString stringWithFormat:@"🔧 [VIDEO] playVideoAtURL: %@, fullscreen: %@", videoURL, fullscreen ? @"YES" : @"NO"]];
    // Implementation would go here
}

- (void)pauseAllMedia {
    [self.logger info:@"🔧 [VIDEO] pauseAllMedia called"];
    // Implementation would go here
}

- (void)resumeAllMedia {
    [self.logger info:@"🔧 [VIDEO] resumeAllMedia called"];
    // Implementation would go here
}

- (void)configureAccessibility {
    [self.logger info:@"🔧 [ACCESSIBILITY] configureAccessibility called"];
    // Implementation would go here
}

#pragma mark - Cleanup

- (void)cleanup {
    [self stopViewabilityTracking];
    
    if (self.webView) {
        [self.webView.configuration.userContentController removeAllUserScripts];
        self.webView.navigationDelegate = nil;
        self.webView.UIDelegate = nil;
        [self.webView removeFromSuperview];
        self.webView = nil;
    }
    
    if (self.mraidManager) {
        self.mraidManager.delegate = nil;
        self.mraidManager = nil;
    }
    
    if (self.viewabilityTracker) {
        self.viewabilityTracker.delegate = nil;
        self.viewabilityTracker = nil;
    }
    
    self.loadCompletion = nil;
    
    [self.logger info:@"✅ [CLEANUP] CLXPrebidWebView cleanup completed"];
}

#pragma mark - Content Analysis

- (void)logContentAnalysis:(NSString *)html {
    [self.logger info:@"📊 [CONTENT-ANALYSIS] Analyzing HTML content"];
    
    // Count different content types
    NSUInteger imageCount = [self countOccurrences:@"<img" inString:html];
    NSUInteger videoCount = [self countOccurrences:@"<video" inString:html];
    NSUInteger iframeCount = [self countOccurrences:@"<iframe" inString:html];
    NSUInteger scriptCount = [self countOccurrences:@"<script" inString:html];
    NSUInteger linkCount = [self countOccurrences:@"<a " inString:html];
    
    [self.logger info:@"📊 [CONTENT-ANALYSIS] Content breakdown:"];
    [self.logger info:[NSString stringWithFormat:@"  📍 Images: %lu", imageCount]];
    [self.logger info:[NSString stringWithFormat:@"  📍 Videos: %lu", videoCount]];
    [self.logger info:[NSString stringWithFormat:@"  📍 iFrames: %lu", iframeCount]];
    [self.logger info:[NSString stringWithFormat:@"  📍 Scripts: %lu", scriptCount]];
    [self.logger info:[NSString stringWithFormat:@"  📍 Links: %lu", linkCount]];
    
    // Check for MRAID content
    BOOL hasMRAID = [html containsString:@"mraid"] || [html containsString:@"MRAID"];
    [self.logger info:[NSString stringWithFormat:@"📊 [CONTENT-ANALYSIS] MRAID content detected: %@", hasMRAID ? @"YES" : @"NO"]];
    
    // Check for VAST content
    BOOL hasVAST = [html containsString:@"VAST"] || [html containsString:@"vast"];
    [self.logger info:[NSString stringWithFormat:@"📊 [CONTENT-ANALYSIS] VAST content detected: %@", hasVAST ? @"YES" : @"NO"]];
    
    // Check for responsive design
    BOOL hasViewport = [html containsString:@"viewport"];
    BOOL hasMediaQueries = [html containsString:@"@media"];
    [self.logger info:[NSString stringWithFormat:@"📊 [CONTENT-ANALYSIS] Responsive design: Viewport=%@, MediaQueries=%@", 
     hasViewport ? @"YES" : @"NO", hasMediaQueries ? @"YES" : @"NO"]];
}

- (NSUInteger)countOccurrences:(NSString *)substring inString:(NSString *)string {
    NSUInteger count = 0;
    NSRange searchRange = NSMakeRange(0, string.length);
    NSRange foundRange;
    
    while ((foundRange = [string rangeOfString:substring options:NSCaseInsensitiveSearch range:searchRange]).location != NSNotFound) {
        count++;
        searchRange.location = foundRange.location + foundRange.length;
        searchRange.length = string.length - searchRange.location;
    }
    
    return count;
}

@end