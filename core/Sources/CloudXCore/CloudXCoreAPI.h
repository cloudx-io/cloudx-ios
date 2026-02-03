#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXInitializationConfiguration.h>
#import <CloudXCore/CLXSdkConfiguration.h>

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

@class CLXBannerAdView;
@class CLXSDKConfigResponse;
@class CLXSDKConfigAdUnit;
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
 * Initialize the SDK with a configuration object
 * @param configuration The initialization configuration
 * @param completion A completion handler called when initialization completes.
 *                   On success, sdkConfiguration is non-nil and error is nil.
 *                   On failure, sdkConfiguration is nil and error contains failure details.
 * @discussion This is the preferred initialization method. Use CLXInitializationConfiguration
 * to configure the SDK before initialization.
 *
 * Example:
 * @code
 * CLXInitializationConfiguration *config =
 *     [CLXInitializationConfiguration configurationWithAppKey:@"your-app-key"
 *         builderBlock:^(CLXInitializationConfigurationBuilder *builder) {
 *             builder.pluginVersion = @"flutter-1.2.0";
 *         }];
 * [[CloudXCore shared] initializeWithConfiguration:config completion:^(CLXSdkConfiguration *sdkConfiguration, CLXError *error) {
 *     if (sdkConfiguration) {
 *         NSLog(@"SDK initialized successfully");
 *     } else {
 *         NSLog(@"SDK initialization failed: %@", error.localizedDescription);
 *     }
 * }];
 * @endcode
 */
- (void)initializeWithConfiguration:(CLXInitializationConfiguration *)configuration
                         completion:(nullable void (^)(CLXSdkConfiguration * _Nullable sdkConfiguration, CLXError * _Nullable error))completion
    NS_SWIFT_NAME(initialize(with:completion:));

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
 * @return A CLXBannerAdView object
 * @discussion Set the delegate property on the returned object to receive ad events
 */
- (nullable CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement
                                           viewController:(UIViewController *)viewController
    NS_SWIFT_NAME(createBanner(placement:viewController:));

/**
 * Create a MREC ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param viewController The view controller in which the ad will be displayed
 * @return A CLXBannerAdView object
 * @discussion Set the delegate property on the returned object to receive ad events
 */
- (nullable CLXBannerAdView *)createMRECWithPlacement:(NSString *)placement
                                          viewController:(UIViewController *)viewController
    NS_SWIFT_NAME(createMREC(placement:viewController:));

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
- (nullable CLXSDKConfigAdUnit *)placementConfigForName:(NSString *)placementName;

/**
 * Get all available placement names from the SDK configuration
 * @return Array of placement names, or empty array if SDK not initialized or no placements configured
 * @discussion Internal API used for detailed error messages when placement validation fails
 */
- (NSArray<NSString *> *)availablePlacementNames;

@end

NS_ASSUME_NONNULL_END