//
//  CLXRendererWebView.h
//  CloudXRenderer
//
//  Advanced MRAID 3.0 compliant web view with performance optimization
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import "CLXMRAIDManager.h"
#import "CLXViewabilityTracker.h"
#import "CLXPerformanceManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CLXRendererWebView;

/**
 * Enhanced delegate protocol for comprehensive ad events
 */
@protocol CLXRendererWebViewDelegate <NSObject>

@required
- (nullable UIViewController *)viewControllerForPresentingModals;

@optional
- (void)webViewReadyToDisplay:(CLXRendererWebView *)webView;
- (void)webView:(CLXRendererWebView *)webView failedToLoadWithError:(NSError *)error;
- (void)webView:(CLXRendererWebView *)webView receivedClickthroughLink:(NSURL *)url;

// MRAID events
- (void)webView:(CLXRendererWebView *)webView mraidStateChanged:(CLXMRAIDState)state;
- (void)webView:(CLXRendererWebView *)webView mraidViewabilityChanged:(BOOL)viewable;
- (void)webView:(CLXRendererWebView *)webView didRequestResize:(CGSize)size;
- (void)webView:(CLXRendererWebView *)webView didRequestExpand:(nullable NSURL *)url;

// Viewability events
- (void)webView:(CLXRendererWebView *)webView viewabilityChanged:(BOOL)viewable measurement:(CLXViewabilityMeasurement *)measurement;
- (void)webView:(CLXRendererWebView *)webView metViewabilityThreshold:(CLXViewabilityMeasurement *)measurement;

// Video events
- (void)webView:(CLXRendererWebView *)webView didRequestPlayVideo:(NSURL *)videoURL;
- (void)webView:(CLXRendererWebView *)webView videoDidComplete:(BOOL)completed;

// Interactive events  
- (void)webView:(CLXRendererWebView *)webView didRequestStorePicture:(NSURL *)imageURL;
- (void)webView:(CLXRendererWebView *)webView didRequestCreateCalendarEvent:(NSDictionary *)eventData;

@end

/**
 * Advanced MRAID 3.0 compliant web view with comprehensive feature support
 */
@interface CLXRendererWebView : UIView <CLXMRAIDManagerDelegate, CLXViewabilityTrackerDelegate>

// Core properties
@property (nonatomic, weak, nullable) id<CLXRendererWebViewDelegate> delegate;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) WKWebView *internalWebView;
@property (nonatomic, assign) BOOL inspectable API_AVAILABLE(ios(16.4));

// MRAID properties
@property (nonatomic, strong, readonly) CLXMRAIDManager *mraidManager;
@property (nonatomic, assign, readonly) CLXMRAIDState mraidState;
@property (nonatomic, assign) CLXMRAIDPlacementType placementType;

// Viewability properties
@property (nonatomic, strong, readonly) CLXViewabilityTracker *viewabilityTracker;
@property (nonatomic, assign, readonly) BOOL isViewable;
@property (nonatomic, assign) CLXViewabilityStandard viewabilityStandard;

// Performance properties
@property (nonatomic, assign) BOOL optimizeForPerformance; // Default: YES
@property (nonatomic, assign) BOOL enableViewabilityTracking; // Default: YES
@property (nonatomic, assign) BOOL preloadResources; // Default: YES

// Video properties
@property (nonatomic, assign) BOOL allowsInlineMediaPlayback; // Default: YES
@property (nonatomic, assign) BOOL requiresUserActionForPlayback; // Default: NO

/**
 * Initialize with frame and placement type
 */
- (instancetype)initWithFrame:(CGRect)frame placementType:(CLXMRAIDPlacementType)placementType;

/**
 * Load HTML content with advanced optimization
 */
- (void)loadHTML:(NSString *)html baseURL:(nullable NSURL *)baseURL;

/**
 * Load HTML with performance optimizations and preloading
 */
- (void)loadOptimizedHTML:(NSString *)html 
                  baseURL:(nullable NSURL *)baseURL
               completion:(nullable void (^)(BOOL success, NSError *_Nullable error))completion;

/**
 * MRAID control methods
 */
- (void)expandToFullScreen;
- (void)collapseFromExpanded;
- (void)resizeToSize:(CGSize)size;
- (void)closeAd;

/**
 * Viewability control
 */
- (void)startViewabilityTracking;
- (void)stopViewabilityTracking;
- (void)updateViewportVisibility:(CGRect)visibleRect;

/**
 * Performance monitoring
 */
- (void)enablePerformanceMonitoring;
- (CLXPerformanceMetrics *)currentPerformanceMetrics;

/**
 * Resource management
 */
- (void)preloadResourcesInHTML:(NSString *)html completion:(nullable void (^)(BOOL success))completion;
- (void)clearResourceCache;
- (void)optimizeMemoryUsage;

/**
 * Video support
 */
- (void)playVideoAtURL:(NSURL *)videoURL fullscreen:(BOOL)fullscreen;
- (void)pauseAllMedia;
- (void)resumeAllMedia;

/**
 * Accessibility
 */
- (void)configureAccessibility;

/**
 * Cleanup
 */
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END