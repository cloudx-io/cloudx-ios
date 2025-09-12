#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations for public interfaces
@protocol CLXBannerDelegate;
@protocol CLXInterstitialDelegate;
@protocol CLXRewardedDelegate;
@protocol CLXNativeDelegate;
@protocol CLXInterstitial;
@protocol CLXRewardedInterstitial;

@class CLXBannerAdView;
@class CLXNativeAdView;
@class CLXSDKConfigResponse;

/**
 * The main class of the CloudX SDK.
 * Use this class to initialise the SDK and create ads.
 */
@interface CloudXCore : NSObject

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
 * Log data dictionary
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *logsData;

/**
 * Whether the SDK is initialized
 */
@property (nonatomic, readonly) BOOL isInitialised;



/**
 * Initialise the SDK to start serving ads
 * @param appKey The app key provided by CloudX
 * @param completion A completion handler that will be called once the SDK is initialised
 */
- (void)initSDKWithAppKey:(NSString *)appKey completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * Initialise the SDK to start serving ads with hashed user ID
 * @param appKey The app key provided by CloudX
 * @param hashedUserID The hashed user ID provided by CloudX
 * @param completion A completion handler that will be called once the SDK is initialised
 */
- (void)initSDKWithAppKey:(NSString *)appKey hashedUserID:(NSString *)hashedUserID completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * Provide the user details for auction requests
 * @param hashedUserID The hashedUserID provided by CloudX
 */
- (void)provideUserDetailsWithHashedUserID:(NSString *)hashedUserID;

/**
 * Provide the user details for auction requests
 * @param key The key provided by CloudX
 * @param value The value provided by CloudX
 */
- (void)useHashedKeyValueWithKey:(NSString *)key value:(NSString *)value;

/**
 * Provide the user details for auction requests
 * @param userDictionary The dictionary of key-value pairs provided by CloudX
 */
- (void)useKeyValuesWithUserDictionary:(NSDictionary<NSString *, NSString *> *)userDictionary;

/**
 * Provide the user details for auction requests
 * @param bidder The bidder name
 * @param key The key provided by CloudX
 * @param value The value provided by CloudX
 */
- (void)useBidderKeyValueWithBidder:(NSString *)bidder key:(NSString *)key value:(NSString *)value;

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
                                                      tmax:(nullable NSNumber *)tmax;

/**
 * Create a MREC ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param viewController The view controller in which the ad will be displayed
 * @param delegate The delegate to receive ad events
 * @return A CLXBannerAdView object
 */
- (nullable CLXBannerAdView *)createMRECWithPlacement:(NSString *)placement
                                          viewController:(UIViewController *)viewController
                                                delegate:(nullable id<CLXBannerDelegate>)delegate;

/**
 * Create an interstitial ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param delegate The delegate to receive ad events
 * @return A CLXInterstitial object
 */
- (nullable id<CLXInterstitial>)createInterstitialWithPlacement:(NSString *)placement
                                                       delegate:(nullable id<CLXInterstitialDelegate>)delegate;

/**
 * Create a rewarded ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param delegate The delegate to receive ad events
 * @return A CLXRewardedInterstitial object
 */
- (nullable id<CLXRewardedInterstitial>)createRewardedWithPlacement:(NSString *)placement
                                                           delegate:(nullable id<CLXRewardedDelegate>)delegate;

/**
 * Create a native ad
 * @param placement The placement name. This should match the placement name in the CloudX dashboard
 * @param viewController The view controller in which the ad will be displayed
 * @param delegate The delegate to receive ad events
 * @return A CLXNativeAdView object
 */
- (nullable CLXNativeAdView *)createNativeAdWithPlacement:(NSString *)placement
                                              viewController:(UIViewController *)viewController
                                                    delegate:(nullable id<CLXNativeDelegate>)delegate;

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
 * @discussion COPPA is now supported with GPP implementation and will be included in bid requests.
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

@end

NS_ASSUME_NONNULL_END 