//
//  CLXMRAIDManager.h
//  CloudXPrebidAdapter
//
//  Comprehensive MRAID 3.0 implementation with full feature support
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXMRAIDManager;

/**
 * MRAID states as defined in MRAID 3.0 specification
 */
typedef NS_ENUM(NSInteger, CLXMRAIDState) {
    CLXMRAIDStateLoading,
    CLXMRAIDStateDefault,
    CLXMRAIDStateExpanded,
    CLXMRAIDStateResized,
    CLXMRAIDStateHidden
};

/**
 * MRAID placement types
 */
typedef NS_ENUM(NSInteger, CLXMRAIDPlacementType) {
    CLXMRAIDPlacementTypeInline,
    CLXMRAIDPlacementTypeInterstitial
};

/**
 * MRAID orientation properties
 */
typedef NS_ENUM(NSInteger, CLXMRAIDOrientation) {
    CLXMRAIDOrientationPortrait,
    CLXMRAIDOrientationLandscape,
    CLXMRAIDOrientationNone
};

/**
 * Delegate protocol for MRAID events
 */
@protocol CLXMRAIDManagerDelegate <NSObject>

@optional
- (void)mraidManager:(CLXMRAIDManager *)manager didChangeState:(CLXMRAIDState)state;
- (void)mraidManager:(CLXMRAIDManager *)manager didChangeViewable:(BOOL)viewable;
- (void)mraidManager:(CLXMRAIDManager *)manager didReceiveCloseRequest:(nullable NSDictionary *)parameters;
- (void)mraidManager:(CLXMRAIDManager *)manager didRequestOpenURL:(NSURL *)url;
- (void)mraidManager:(CLXMRAIDManager *)manager didRequestResize:(CGSize)size;
- (void)mraidManager:(CLXMRAIDManager *)manager didRequestExpand:(nullable NSURL *)url;
- (void)mraidManager:(CLXMRAIDManager *)manager didRequestPlayVideo:(NSURL *)url;
- (void)mraidManager:(CLXMRAIDManager *)manager didRequestStorePicture:(NSURL *)url;
- (void)mraidManager:(CLXMRAIDManager *)manager didRequestCreateCalendarEvent:(NSDictionary *)parameters;
- (UIViewController *)viewControllerForPresentingModalInMRAIDManager:(CLXMRAIDManager *)manager;

@end

/**
 * Comprehensive MRAID 3.0 Manager
 * Handles all MRAID functionality including advanced features
 */
@interface CLXMRAIDManager : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) id<CLXMRAIDManagerDelegate> delegate;
@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nonatomic, assign, readonly) CLXMRAIDState currentState;
@property (nonatomic, assign, readonly) BOOL isViewable;
@property (nonatomic, assign, readonly) CLXMRAIDPlacementType placementType;
@property (nonatomic, assign) CGRect adFrame;
@property (nonatomic, assign) CGRect maxSize;
@property (nonatomic, assign) CGRect screenSize;
@property (nonatomic, assign) BOOL supportsInlineVideo;

/**
 * Initialize with webview and placement type
 */
- (instancetype)initWithWebView:(WKWebView *)webView 
                  placementType:(CLXMRAIDPlacementType)placementType;

/**
 * Inject complete MRAID 3.0 JavaScript implementation
 */
- (NSString *)getMRAIDJavaScript;

/**
 * Update viewability state (call when view enters/exits viewport)
 */
- (void)updateViewability:(BOOL)viewable;

/**
 * Update current state
 */
- (void)updateState:(CLXMRAIDState)state;

/**
 * Update exposure change (for viewability tracking)
 */
- (void)updateExposure:(CGFloat)exposedPercentage exposedRect:(CGRect)exposedRect;

/**
 * Handle device orientation change
 */
- (void)handleOrientationChange:(UIInterfaceOrientation)orientation;

/**
 * Handle app background/foreground events
 */
- (void)handleAppBackground;
- (void)handleAppForeground;

/**
 * Process resize request
 */
- (BOOL)processResizeRequest:(CGSize)size allowOffscreen:(BOOL)allowOffscreen;

/**
 * Process expand request  
 */
- (BOOL)processExpandRequest:(nullable NSURL *)url;

/**
 * Process close request
 */
- (void)processCloseRequest;

/**
 * Clean up resources
 */
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END