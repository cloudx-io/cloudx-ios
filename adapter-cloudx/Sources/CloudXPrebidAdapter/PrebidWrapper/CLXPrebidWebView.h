//
//  CLXPrebidWebView.h
//  CloudXPrebidAdapter
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

@class CLXPrebidWebView;

/**
 * Enhanced delegate protocol for comprehensive ad events
 */
@protocol CLXPrebidWebViewDelegate <NSObject>

@required
- (nullable UIViewController *)viewControllerForPresentingModals;

@optional
- (void)webViewReadyToDisplay:(CLXPrebidWebView *)webView;
- (void)webView:(CLXPrebidWebView *)webView failedToLoadWithError:(NSError *)error;
- (void)webView:(CLXPrebidWebView *)webView receivedClickthroughLink:(NSURL *)url;

// MRAID events
- (void)webView:(CLXPrebidWebView *)webView mraidStateChanged:(CLXMRAIDState)state;
- (void)webView:(CLXPrebidWebView *)webView mraidViewabilityChanged:(BOOL)viewable;
- (void)webView:(CLXPrebidWebView *)webView didRequestResize:(CGSize)size;
- (void)webView:(CLXPrebidWebView *)webView didRequestExpand:(nullable NSURL *)url;

// Viewability events
- (void)webView:(CLXPrebidWebView *)webView viewabilityChanged:(BOOL)viewable measurement:(CLXViewabilityMeasurement *)measurement;
- (void)webView:(CLXPrebidWebView *)webView metViewabilityThreshold:(CLXViewabilityMeasurement *)measurement;

// Video events
- (void)webView:(CLXPrebidWebView *)webView didRequestPlayVideo:(NSURL *)videoURL;
- (void)webView:(CLXPrebidWebView *)webView videoDidComplete:(BOOL)completed;

// Interactive events  
- (void)webView:(CLXPrebidWebView *)webView didRequestStorePicture:(NSURL *)imageURL;
- (void)webView:(CLXPrebidWebView *)webView didRequestCreateCalendarEvent:(NSDictionary *)eventData;

@end

/**
 * Advanced MRAID 3.0 compliant web view with comprehensive feature support
 */
@interface CLXPrebidWebView : UIView <CLXMRAIDManagerDelegate, CLXViewabilityTrackerDelegate>

// Core properties
@property (nonatomic, weak, nullable) id<CLXPrebidWebViewDelegate> delegate;
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