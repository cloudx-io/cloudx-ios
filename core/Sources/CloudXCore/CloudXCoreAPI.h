#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Notification posted when SDK initialization completes
 * @discussion Internal notification used by ad objects to coordinate queued operations
 */
FOUNDATION_EXPORT NSString * const CLXSDKInitializedNotification;

// Forward declarations for public interfaces
@protocol CLXBannerDelegate;
@protocol CLXInterstitialDelegate;
@protocol CLXRewardedDelegate;
@protocol CLXNativeDelegate;

@class CLXBannerAdView;
@class CLXNativeAdView;
@class CLXSDKConfigResponse;
@class CLXSDKConfigPlacement;
@class CLXInterstitial;
@class CLXRewarded;

/**
 * The main class of the CloudX SDK.
 * Use this class to initialise the SDK and create ads.
 * @discussion Thread-safe singleton. All methods should be called from the main thread.
 */
@interface CloudXCore : NSObject

/**
 * Use the shared singleton instance instead
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Use the shared singleton instance instead
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 * The shared instance of CloudXCore
 */
@property (class, nonatomic, readonly) CloudXCore *shared;

/**
 * The version of the CloudX SDK
 */
@property (nonatomic, readonly) NSString *sdkVersion;

/**
 * Indicates whether the SDK has completed initialization
 */
@property (nonatomic, readonly) BOOL isInitialized;

/**
 * Initialize the SDK to start serving ads
 * @param appKey The app key provided by CloudX
 * @param completion A completion handler that will be called once the SDK is initialized
 * @discussion Test mode is now server-controlled via deviceConfig.
 * 
 * To enable test mode for a device:
 * 1. Initialize the SDK and check logs for your device IFA
 * 2. Whitelist the IFA on the CloudX server dashboard
 * 3. The server will return deviceConfig.test = 1 for whitelisted devices
 * 
 * When test mode is enabled:
 * - Bid requests will include the test flag (OpenRTB spec)
 * - Adapter SDKs will be configured for test mode (e.g., Meta test ads)
 * - No real monetization will occur
 */
- (void)initializeSDKWithAppKey:(NSString *)appKey completion:(nullable void (^)(BOOL success, CLXError * _Nullable error))completion
    NS_SWIFT_NAME(initializeSDK(appKey:completion:));

/**
 * Set the hashed user ID for auction requests
 * @param hashedUserID The hashedUserID provided by CloudX
 */
- (void)setHashedUserID:(NSString *)hashedUserID
    NS_SWIFT_NAME(setHashedUserID(_:));

/**
 * Set a user-level key-value pair for targeting
 * @param key The targeting key
 * @param value The targeting value
 * @discussion User-level key-values are injected into bid requests at server-configured paths.
 * These values are typically user-specific targeting parameters and will be cleared
 * if privacy regulations require removing personal data.
 */
- (void)setUserKeyValue:(NSString *)key value:(NSString *)value;

/**
 * Set an app-level key-value pair for targeting
 * @param key The targeting key
 * @param value The targeting value
 * @discussion App-level key-values are injected into bid requests at server-configured paths.
 * These values are typically app-specific targeting parameters and are not affected
 * by privacy regulations.
 */
- (void)setAppKeyValue:(NSString *)key value:(NSString *)value;

/**
 * Clear all user and app-level key-value pairs
 * @discussion Removes all previously set targeting key-value pairs
 */
- (void)clearAllKeyValues;

/**
 * Create a banner ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param viewController The view controller in which the ad will be displayed
 * @param delegate The delegate to receive ad events
 * @return A CLXBannerAdView object
 */
- (nullable CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement
                                           viewController:(UIViewController *)viewController
                                                 delegate:(nullable id<CLXBannerDelegate>)delegate
    NS_SWIFT_NAME(createBanner(placement:viewController:delegate:));

/**
 * Create a MREC ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param viewController The view controller in which the ad will be displayed
 * @param delegate The delegate to receive ad events
 * @return A CLXBannerAdView object
 */
- (nullable CLXBannerAdView *)createMRECWithPlacement:(NSString *)placement
                                          viewController:(UIViewController *)viewController
                                                delegate:(nullable id<CLXBannerDelegate>)delegate
    NS_SWIFT_NAME(createMREC(placement:viewController:delegate:));

/**
 * Create an interstitial ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @return A CLXInterstitial object
 * @discussion Set the delegate property on the returned object to receive ad events
 */
- (nullable CLXInterstitial *)createInterstitialWithPlacement:(NSString *)placement
    NS_SWIFT_NAME(createInterstitial(placement:));

/**
 * Create a rewarded ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @return A CLXRewarded object
 * @discussion Set the delegate property on the returned object to receive ad events
 */
- (nullable CLXRewarded *)createRewardedWithPlacement:(NSString *)placement
    NS_SWIFT_NAME(createRewarded(placement:));

/**
 * Create a native ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param viewController The view controller in which the ad will be displayed
 * @param delegate The delegate to receive ad events
 * @return A CLXNativeAdView object
 */
- (nullable CLXNativeAdView *)createNativeAdWithPlacement:(NSString *)placement
                                              viewController:(UIViewController *)viewController
                                                    delegate:(nullable id<CLXNativeDelegate>)delegate
    NS_SWIFT_NAME(createNativeAd(placement:viewController:delegate:));

#pragma mark - Visual Debugging

/**
 * Enable or disable the visual debugging overlay
 * @param enabled YES to show the debug overlay, NO to hide it
 * @discussion When enabled, shows a floating debug button that provides:
 * - Click visual feedback (border highlight on ad clicks)
 * - Error display in ad containers (shows load/display errors)
 * - Log viewer (tap the button to see SDK logs)
 * - Error flash (button flashes red when errors occur)
 *
 * This is independent from testMode - you can debug real production ads.
 * The overlay appears immediately when enabled and can be called at any time.
 *
 * Example:
 * @code
 * // Enable visual debugging for live ads
 * [CloudXCore setVisualDebuggingEnabled:YES];
 * @endcode
 */
+ (void)setVisualDebuggingEnabled:(BOOL)enabled;

/**
 * Check if visual debugging is currently enabled
 * @return YES if visual debugging overlay is enabled, NO otherwise
 */
+ (BOOL)isVisualDebuggingEnabled;

#pragma mark - Logging Control

/**
 * Set minimum log level for SDK logging
 * @param minLogLevel The minimum log level (CLXLogLevelVerbose, CLXLogLevelDebug, CLXLogLevelInfo, CLXLogLevelWarn, CLXLogLevelError, CLXLogLevelNone)
 * @discussion Controls which log messages are displayed. Only logs at or above this level will be shown.
 * Use CLXLogLevelNone to disable all logging. Call this method early in your app lifecycle.
 */
+ (void)setMinLogLevel:(CLXLogLevel)minLogLevel;

/**
 * Enable or disable emojis in logs
 * @param enabled YES to show emojis (default), NO for plain text
 * @discussion Disable emojis when exporting logs to systems that don't support them (Datadog, Splunk, etc)
 */
+ (void)setLoggingEmojisEnabled:(BOOL)enabled;

/**
 * Enable or disable timestamps in logs
 * @param enabled YES to show timestamps, NO to hide (default)
 * @discussion Timestamps are formatted as HH:mm:ss.SSS and appear after [CloudX]. Useful for debugging timing issues.
 */
+ (void)setLoggingTimestampsEnabled:(BOOL)enabled;

#pragma mark - SDK Lifecycle

/**
 * Deinitialize the SDK and clean up resources
 * @discussion Tears down the SDK, releases resources, and resets the initialization state.
 * After calling this, you can reinitialize the SDK if needed.
 */
- (void)deinitialize;

#pragma mark - Adapter Readiness (Internal)

/**
 * Check if a specific adapter has completed initialization
 * @param adapterName The name of the adapter (e.g., "meta", "vungle")
 * @return YES if the adapter is ready, NO otherwise
 * @discussion Internal API used by bid request logic to avoid race conditions during SDK initialization
 */
- (BOOL)isAdapterReady:(NSString *)adapterName;

/**
 * Look up placement configuration by name
 * @param placementName The placement name
 * @return Placement configuration or nil if not found
 * @discussion Internal API used by ad objects to look up placement configuration after SDK initialization
 */
- (nullable CLXSDKConfigPlacement *)placementConfigForName:(NSString *)placementName;

@end

NS_ASSUME_NONNULL_END