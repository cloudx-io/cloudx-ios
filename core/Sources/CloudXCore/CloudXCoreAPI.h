#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations for public interfaces
@protocol CLXBannerDelegate;
@protocol CLXInterstitialDelegate;
@protocol CLXRewardedDelegate;
@protocol CLXNativeDelegate;

@class CLXBannerAdView;
@class CLXNativeAdView;
@class CLXSDKConfigResponse;
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
 * User ID for tracking
 */
@property (nonatomic, copy, nullable) NSString *userID;

/**
 * Whether the SDK is initialized
 */
@property (nonatomic, readonly) BOOL isInitialized;



/**
 * Initialize the SDK to start serving ads
 * @param appKey The app key provided by CloudX
 * @param completion A completion handler that will be called once the SDK is initialized
 */
- (void)initializeSDKWithAppKey:(NSString *)appKey completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion
    NS_SWIFT_NAME(initializeSDK(appKey:completion:));

/**
 * Initialize the SDK to start serving ads with hashed user ID
 * @param appKey The app key provided by CloudX
 * @param hashedUserID The hashed user ID provided by CloudX
 * @param completion A completion handler that will be called once the SDK is initialized
 */
- (void)initializeSDKWithAppKey:(NSString *)appKey hashedUserID:(NSString *)hashedUserID completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion
    NS_SWIFT_NAME(initializeSDK(appKey:hashedUserID:completion:));

/**
 * Set the hashed user ID for auction requests
 * @param hashedUserID The hashedUserID provided by CloudX
 */
- (void)setHashedUserID:(NSString *)hashedUserID
    NS_SWIFT_NAME(setHashedUserID(_:));

/**
 * Set a hashed key-value pair for auction requests
 * @param key The key provided by CloudX
 * @param value The value provided by CloudX
 */
- (void)setHashedKeyValue:(NSString *)key value:(NSString *)value
    NS_SWIFT_NAME(setHashedKeyValue(key:value:));

/**
 * Set multiple key-value pairs for auction requests
 * @param userDictionary The dictionary of key-value pairs provided by CloudX
 */
- (void)setKeyValueDictionary:(NSDictionary<NSString *, NSString *> *)userDictionary
    NS_SWIFT_NAME(setKeyValueDictionary(_:));

/**
 * Set a bidder-specific key-value pair for auction requests
 * @param bidder The bidder name
 * @param key The key provided by CloudX
 * @param value The value provided by CloudX
 */
- (void)setBidderKeyValue:(NSString *)bidder key:(NSString *)key value:(NSString *)value
    NS_SWIFT_NAME(setBidderKeyValue(bidder:key:value:));

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
 * @param tmax Optional timeout value for bid requests
 * @return A CLXBannerAdView object
 */
- (nullable CLXBannerAdView *)createBannerWithPlacement:(NSString *)placement
                                            viewController:(UIViewController *)viewController
                                                  delegate:(nullable id<CLXBannerDelegate>)delegate
                                                      tmax:(nullable NSNumber *)tmax
    NS_SWIFT_NAME(createBanner(placement:viewController:delegate:tmax:));

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
 * @param delegate The delegate to receive ad events
 * @return A CLXInterstitial object
 */
- (nullable CLXInterstitial *)createInterstitialWithPlacement:(NSString *)placement
                                                     delegate:(nullable id<CLXInterstitialDelegate>)delegate
    NS_SWIFT_NAME(createInterstitial(placement:delegate:));

/**
 * Create a rewarded ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param delegate The delegate to receive ad events
 * @return A CLXRewarded object
 */
- (nullable CLXRewarded *)createRewardedWithPlacement:(NSString *)placement
                                             delegate:(nullable id<CLXRewardedDelegate>)delegate
    NS_SWIFT_NAME(createRewarded(placement:delegate:));

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

/**
 * Track SDK errors for analytics reporting
 * @param error The error to track
 */
+ (void)trackSDKError:(NSError *)error;

#pragma mark - Privacy Settings (Matching Android API)

/**
 * Set CCPA privacy string
 * @param ccpaPrivacyString The CCPA privacy string (e.g., "1YNN")
 */
+ (void)setCCPAPrivacyString:(nullable NSString *)ccpaPrivacyString;

/**
 * Set whether user has given consent (GDPR)
 * @param isUserConsent YES if user has given consent, NO otherwise
 * @discussion ⚠️ GDPR is not yet supported by CloudX servers. Please contact CloudX if you need GDPR support. CCPA is fully supported.
 */
+ (void)setIsUserConsent:(BOOL)isUserConsent;

/**
 * Set whether user is age-restricted (COPPA)
 * @param isAgeRestrictedUser YES if user is age-restricted, NO otherwise
 * @discussion COPPA data clearing is implemented but not included in bid requests (server limitation). Android parity for data clearing behavior.
 */
+ (void)setIsAgeRestrictedUser:(BOOL)isAgeRestrictedUser;

/**
 * Set "do not sell" preference (CCPA)
 * @param isDoNotSell YES to opt-out of data selling, NO otherwise
 * @discussion CCPA "do not sell my personal information" flag - converts to CCPA privacy string format
 */
+ (void)setIsDoNotSell:(BOOL)isDoNotSell;

#pragma mark - GPP (Global Privacy Platform) Settings

/**
 * Set GPP consent string
 * @param gppString The GPP consent string from IAB framework
 * @discussion GPP (Global Privacy Platform) compliance string for comprehensive privacy management
 */
+ (void)setGPPString:(nullable NSString *)gppString;

/**
 * Get GPP consent string
 * @return The current GPP consent string, or nil if not set
 * @discussion Retrieves the stored GPP consent string
 */
+ (nullable NSString *)getGPPString;

/**
 * Set GPP section IDs
 * @param gppSid Array of GPP section IDs indicating applicable privacy frameworks
 * @discussion GPP section identifiers (e.g., @[@7, @8] for US-National and US-CA)
 */
+ (void)setGPPSid:(nullable NSArray<NSNumber *> *)gppSid;

/**
 * Get GPP section IDs
 * @return Array of GPP section IDs, or nil if not set
 * @discussion Retrieves the stored GPP section identifiers
 */
+ (nullable NSArray<NSNumber *> *)getGPPSid;

#pragma mark - Logging Control

/**
 * Enable or disable SDK logging
 * @param enabled YES to enable logging, NO to disable
 * @discussion Controls verbose logging output from the SDK. Disabled by default in production.
 * Call this method early in your app lifecycle, before SDK initialization, to see all logs.
 */
+ (void)setLoggingEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END