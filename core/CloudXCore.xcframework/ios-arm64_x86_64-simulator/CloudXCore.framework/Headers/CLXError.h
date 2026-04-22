//
// CLXError.h
// CloudXCore
//
// Industry-standard error codes following common ad SDK patterns
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Loss reasons following OpenRTB standard
 * See: OpenRTB 2.5+ specification for standard loss reason codes
 * 
 * Code ranges:
 * 0-99: OpenRTB standard codes
 * 100-199: OpenRTB standard codes (continued)
 * 200+: SDK-specific extended codes for detailed no-bid categorization
 */
typedef NS_ENUM(NSInteger, CLXLossReason) {
    // OpenRTB Standard Codes
    CLXLossReasonBidWon = 0,              // Bid Won (OpenRTB: 0)
    CLXLossReasonInternalError = 1,       // Internal Error (OpenRTB: 1)
    CLXLossReasonLostToHigherBid = 102,   // Lost to Higher Bid (OpenRTB: 102)
    
    // Extended Codes (200+ for SDK-specific no-bid categorization)
    CLXLossReasonCreativeBlocked = 200,   // Creative filtered/blocked by publisher
    CLXLossReasonRateLimited = 201,       // Publisher rate limiting applied
    CLXLossReasonNoFill = 202,            // No inventory available from demand
    CLXLossReasonTimeout = 203,           // Request timed out before response
    CLXLossReasonInvalidBid = 204,        // Malformed or invalid bid response
    CLXLossReasonExpired = 205            // Bid expired before render opportunity
};

/**
 * CloudX SDK error codes.
 *
 * Error codes are organized into ranges by category:
 *
 * - @b 0: General errors.
 * - @b 100–199: Network errors — from CloudX server communication (config fetch, bid requests,
 *   geo lookups). Not from ad network SDKs — those are in the Adapter (600–699) range. These
 *   can surface during initialization (via the completion block) or ad loading (via
 *   @c didFailToLoadAd:error:), depending on which request failed.
 * - @b 200–299: Initialization errors — codes 201–204 are delivered via the initialization
 *   completion block. Code 200 (@c NOT_INITIALIZED) fires when @c load or @c show is called
 *   before initialization completes, delivered via @c didFailToLoadAd:error: or
 *   @c didFailToDisplayAd:error:.
 * - @b 300–399: Ad loading errors — delivered via @c didFailToLoadAd:error: for all ad formats
 *   (banner, MREC, interstitial, rewarded, native).
 * - @b 400–499: Ad display errors — fullscreen ads only (interstitial, rewarded), delivered via
 *   @c didFailToDisplayAd:error:. Banners report load errors only.
 * - @b 500–599: Configuration and setup errors.
 * - @b 600–699: Adapter errors — from individual ad network SDKs, mapped to standardized CloudX
 *   codes. When a single bid fails during ad loading, the publisher sees the specific adapter
 *   error via @c didFailToLoadAd:error:. When multiple bids all fail, the publisher sees
 *   @c NO_FILL (302) instead. During SDK initialization, individual adapter init failures are
 *   not surfaced to the publisher — the SDK tracks them via metrics, and the publisher receives
 *   a successful initialization callback as long as at least one adapter succeeds.
 */
typedef NS_ENUM(NSInteger, CLXErrorCode) {

    // MARK: General (0)

    /**
     * Unexpected exception during initialization, ad loading, or ad display.
     * Also returned when an adapter fails to load but does not report a specific error code.
     *
     * Publisher action: Report to CloudX support with the full error description and stack trace.
     */
    CLXErrorCodeInternalError = 0,

    // MARK: Network (100–199)

    /**
     * HTTP request failed with an I/O error (DNS failure, connection reset, SSL error, etc.).
     *
     * Publisher action: Check device connectivity. If persistent, check for proxy/firewall
     * blocking CloudX endpoints.
     */
    CLXErrorCodeNetworkError = 100,

    /**
     * HTTP request timed out before receiving a response.
     *
     * Publisher action: Check network conditions. May indicate slow connectivity or
     * server-side latency.
     */
    CLXErrorCodeNetworkTimeout = 101,

    /**
     * CloudX server returned HTTP 5xx.
     *
     * Publisher action: Transient — retry happens automatically where applicable.
     * If persistent, report to CloudX support.
     */
    CLXErrorCodeServerError = 102,

    /**
     * CloudX server returned HTTP 4xx (excluding 401 and 429).
     * Typically a malformed request.
     *
     * Publisher action: Check that the request is well-formed and the app key is correct.
     * The SDK will not retry this request.
     */
    CLXErrorCodeClientError = 103,

    /**
     * CloudX server returned HTTP 429.
     *
     * Publisher action: App is being rate-limited. Reduce request frequency or contact
     * CloudX support about limits.
     */
    CLXErrorCodeTooManyRequests = 104,

    /**
     * Server returned HTTP 200 but the body could not be parsed (malformed JSON in config
     * or bid response, or empty geo response).
     *
     * Publisher action: Report to CloudX support — likely a server-side issue.
     */
    CLXErrorCodeInvalidResponse = 105,

    /**
     * No network connectivity detected.
     *
     * Publisher action: Check device connectivity (airplane mode, WiFi/cellular disabled).
     */
    CLXErrorCodeNoConnection = 106,

    // MARK: Initialization (200–299)

    /**
     * @c load or @c show was called before @c initializeWithConfiguration:completion: completed.
     * Delivered via @c didFailToLoadAd:error: or @c didFailToDisplayAd:error:,
     * @b not the initialization completion block.
     *
     * Publisher action: Wait for the initialization completion callback before creating
     * or loading ads.
     */
    CLXErrorCodeNotInitialized = 200,

    /**
     * No adapter modules found at runtime.
     *
     * Publisher action: Add at least one adapter dependency (e.g., @c adapter-meta,
     * @c adapter-vungle) to the app's Podfile or SPM dependencies.
     */
    CLXErrorCodeNoAdaptersFound = 201,

    /**
     * The server returned no ad networks for this app key.
     *
     * Publisher action: Check the CloudX dashboard — no networks are configured for this app.
     */
    CLXErrorCodeNoNetworksConfigured = 202,

    /**
     * The app key passed to @c initializeWithConfiguration:completion: is blank or empty.
     * Also returned when the server responds with HTTP 401 (unauthorized).
     * Checked locally before any network call for blank keys.
     *
     * Publisher action: Fix the app key. It must be non-blank and valid.
     */
    CLXErrorCodeInvalidAppKey = 203,

    /**
     * The server disabled the SDK via traffic control (HTTP 204 with
     * @c X-CloudX-Status: @c SDK_DISABLED). No ads will be served this session.
     *
     * Publisher action: Intentional server-side behavior. Check traffic control settings
     * in the CloudX dashboard.
     */
    CLXErrorCodeSDKDisabled = 204,

    // MARK: Ad Loading (300–399)

    /**
     * The ad unit ID doesn't exist in the server config, or exists but has the wrong type
     * (e.g., loading a banner ad unit as interstitial). The error message lists available
     * ad units of the expected type.
     *
     * Publisher action: Check the ad unit ID matches the dashboard and the correct
     * @c create* method is used.
     */
    CLXErrorCodeInvalidAdUnit = 300,

    /**
     * The bid server returned HTTP 204 with @c X-CloudX-Status: @c ADS_DISABLED.
     * Ads are disabled for this specific ad unit.
     *
     * Publisher action: Check ad unit settings in the CloudX dashboard.
     */
    CLXErrorCodeAdsDisabled = 301,

    /**
     * No ad available. The most common loading error. Causes: (a) bid server returned no bids;
     * (b) bids were returned but all adapters failed to load.
     *
     * Publisher action: Normal — not every request fills. If fill rate is unexpectedly low,
     * check ad unit config and adapter setup.
     */
    CLXErrorCodeNoFill = 302,

    /**
     * @c load was called while a fullscreen ad is currently being displayed.
     *
     * Publisher action: Wait for the ad hidden callback before loading again.
     */
    CLXErrorCodeLoadNotAllowedWhileShowing = 303,

    /**
     * Ad failed to load for unspecified reasons not covered by a more specific error code.
     *
     * Publisher action: Check the error description for details. Report to CloudX support
     * if persistent.
     */
    CLXErrorCodeLoadFailed = 304,

    // MARK: Ad Display (400–499)

    /**
     * @c show was called but no ad is loaded.
     *
     * Publisher action: Check @c isAdReady before calling @c show.
     */
    CLXErrorCodeAdNotReady = 400,

    /**
     * @c show was called while the same ad instance is already on screen.
     *
     * Publisher action: Wait for the ad hidden callback before showing again.
     */
    CLXErrorCodeAdAlreadyShowing = 401,

    // MARK: Configuration (500–599)

    /**
     * The native ad view passed to the SDK is nil or otherwise invalid.
     *
     * Publisher action: Ensure a valid, non-nil native ad view is provided when
     * registering the native ad.
     */
    CLXErrorCodeInvalidNativeView = 500,

    // MARK: Adapter (600–699)

    /**
     * Catch-all for adapter errors with no more specific code.
     *
     * Publisher action: Check the error description for details. Report to CloudX support
     * if persistent.
     */
    CLXErrorCodeAdapterInternalError = 600,

    /**
     * The ad network had no ad for this request.
     *
     * Publisher action: Normal. Not actionable.
     */
    CLXErrorCodeAdapterNoFill = 601,

    /**
     * The adapter was in a state that prevented loading (e.g., already loading or loaded).
     *
     * Publisher action: Avoid calling @c load while a load is in progress.
     */
    CLXErrorCodeAdapterInvalidLoadState = 602,

    /**
     * The ad network SDK is misconfigured (bad placement IDs, invalid app IDs, etc.).
     *
     * Publisher action: Verify ad network credentials and placement IDs in the CloudX dashboard.
     */
    CLXErrorCodeAdapterInvalidConfiguration = 603,

    /**
     * Server-side parameters for this adapter are invalid or missing (e.g., missing placement
     * ID in bid response).
     *
     * Publisher action: Check adapter configuration in the CloudX dashboard.
     */
    CLXErrorCodeAdapterInvalidServerExtras = 604,

    /**
     * The ad network rejected the ad request as invalid.
     *
     * Publisher action: Check ad unit configuration. If persistent, report to CloudX support.
     */
    CLXErrorCodeAdapterBadRequest = 605,

    /**
     * The ad network SDK was not initialized when the adapter tried to load.
     * Usually transient during app startup.
     *
     * Publisher action: If persistent, check adapter initialization logs.
     */
    CLXErrorCodeAdapterNotInitialized = 606,

    /**
     * Exception thrown while creating the adapter object — a bug in the adapter code or
     * incompatible SDK version.
     *
     * Publisher action: Check that adapter and ad network SDK versions are compatible.
     * Report to CloudX support.
     */
    CLXErrorCodeAdapterInitializationError = 607,

    /**
     * The ad network SDK says the ad is not ready to show.
     *
     * Publisher action: Ensure the ad finished loading before displaying.
     */
    CLXErrorCodeAdapterAdNotReady = 608,

    /**
     * The adapter did not finish loading within the SDK's configured timeout. This is CloudX's
     * own timeout wrapping the adapter.
     *
     * Publisher action: May indicate slow network or unresponsive ad network SDK.
     */
    CLXErrorCodeAdapterLoadTimeout = 609,

    /**
     * The ad network SDK itself reported a timeout. Distinct from 609 — this is the network
     * SDK's own timeout, not the CloudX wrapper.
     *
     * Publisher action: May indicate slow network or ad network server issues.
     */
    CLXErrorCodeAdapterTimeout = 610,

    /**
     * The ad network SDK detected no network connectivity.
     *
     * Publisher action: Check device connectivity.
     */
    CLXErrorCodeAdapterNoConnection = 611,

    /**
     * The ad network's own server returned an error.
     *
     * Publisher action: Transient — the ad network may be experiencing issues.
     */
    CLXErrorCodeAdapterServerError = 612,

    /**
     * Collecting a bid token from the ad network SDK timed out during the pre-auction phase.
     *
     * Publisher action: May indicate a slow or unresponsive ad network SDK.
     */
    CLXErrorCodeAdapterBidTokenTimeout = 613,

    /**
     * The adapter does not support bid token collection.
     *
     * Publisher action: Check adapter version and configuration.
     */
    CLXErrorCodeAdapterBidTokenNotSupported = 614,

    /**
     * The ad network's WebView-based creative failed to render.
     *
     * Publisher action: May indicate a device WebView issue or a bad creative.
     * Report to CloudX support if persistent.
     */
    CLXErrorCodeAdapterWebViewError = 615,

    /**
     * The loaded ad expired before @c show was called. Networks typically set 30–60 minute
     * expiry windows.
     *
     * Publisher action: Call @c show sooner after loading, or reload when the ad expires.
     */
    CLXErrorCodeAdapterAdExpired = 616,

    /**
     * The ad network is frequency-capping this placement.
     *
     * Publisher action: Normal — the network limits how often ads are shown.
     * Wait before requesting again.
     */
    CLXErrorCodeAdapterAdFrequencyCapped = 617,

    /**
     * A rewarded ad failed to deliver the reward callback.
     *
     * Publisher action: The user may not have completed the reward interaction.
     * Check rewarded ad flow.
     */
    CLXErrorCodeAdapterRewardError = 618,

    /**
     * A native ad response was missing required creative assets.
     *
     * Publisher action: Report to CloudX support — likely a bad creative from the ad network.
     */
    CLXErrorCodeAdapterMissingNativeAdAssets = 619,

    /**
     * The adapter requires a view controller for ad presentation but one could not be resolved.
     *
     * Publisher action: Ensure @c show is called while a valid view controller is in the
     * foreground.
     */
    CLXErrorCodeAdapterMissingViewController = 620,

    /**
     * The ad network SDK failed to display the ad after loading.
     *
     * Publisher action: Check that the presenting view controller is in the foreground.
     * If persistent, report to CloudX support.
     */
    CLXErrorCodeAdapterDisplayFailed = 621,

    /**
     * The ad network SDK did not complete initialization within the configured timeout
     * (server-configurable per adapter). During SDK init this is tracked internally via
     * metrics and not surfaced to the publisher. May reach the publisher via
     * @c didFailToLoadAd:error: if a subsequent load attempt fails because the adapter
     * never finished initializing.
     *
     * Publisher action: May indicate a slow network or unresponsive ad network SDK.
     * Check device connectivity and adapter logs.
     */
    CLXErrorCodeAdapterInitializationTimeout = 622
};

/**
 * CloudX SDK error domain
 */
extern NSString * const CLXErrorDomain;

/// UserInfo key for the raw HTTP status code in errors created via errorWithHTTPStatusCode:.
extern NSString * const CLXHTTPStatusCodeKey;

/**
 * CloudX SDK error class - industry standard error handling
 */
@interface CLXError : NSError

/**
 * Creates an error with the specified CloudX error code
 * @param code The CloudX error code
 * @return A new CLXError instance
 */
+ (instancetype)errorWithCode:(CLXErrorCode)code;

/**
 * Creates an error with the specified CloudX error code and description
 * @param code The CloudX error code
 * @param description Custom error description
 * @return A new CLXError instance
 */
+ (instancetype)errorWithCode:(CLXErrorCode)code description:(NSString *)description;

/**
 * Creates an error with the specified CloudX error code, description, and underlying error
 * @param code The CloudX error code
 * @param description Custom error description
 * @param underlyingError The original error that caused this error (optional)
 * @return A new CLXError instance
 * @discussion Use this to preserve the root cause error chain for debugging
 */
+ (instancetype)errorWithCode:(CLXErrorCode)code description:(NSString *)description underlyingError:(nullable NSError *)underlyingError;

/**
 * Creates an error with the specified CloudX error code and underlying error, using default description
 * @param code The CloudX error code
 * @param underlyingError The original error that caused this error (optional)
 * @return A new CLXError instance with default description for the error code
 * @discussion Use this when you want consistent error messages across platforms
 */
+ (instancetype)errorWithCode:(CLXErrorCode)code underlyingError:(nullable NSError *)underlyingError;

/**
 * Convenience method to populate an NSError output parameter.
 * Centralizes the nil guard so callers don't need to repeat `if (outError)` checks.
 * @param outError The output error pointer (may be NULL)
 * @param code The CloudX error code
 * @param description Human-readable error description
 */
+ (void)setError:(NSError * __autoreleasing _Nullable * _Nullable)outError code:(CLXErrorCode)code description:(NSString *)description;

/**
 * Converts an NSError to CLXError, preserving the original error code and type if already CLXError
 * @param error The error to convert (may be NSError or CLXError)
 * @param fallbackCode The CLXErrorCode to use for description fallback (not for the error code itself)
 * @return A CLXError instance (original if already CLXError, wrapped otherwise), or nil if error is nil
 * @discussion Use this helper method to safely convert adapter/external errors to CLXError
 *             while maintaining type consistency. The original error code is preserved.
 *             Follows DRY principle - centralizes error conversion logic.
 */
+ (nullable instancetype)errorFromError:(nullable NSError *)error withFallbackCode:(CLXErrorCode)fallbackCode;

/**
 * Creates an error with appropriate CloudX error code based on HTTP status code
 * @param httpStatusCode The HTTP status code from server response
 * @return A new CLXError instance with appropriate error code and description
 */
+ (instancetype)errorWithHTTPStatusCode:(NSInteger)httpStatusCode;

/**
 * Creates an error with appropriate CloudX error code based on HTTP status code and includes server error message
 * @param httpStatusCode The HTTP status code from server response
 * @param serverMessage The error message from the server response body (optional)
 * @return A new CLXError instance with appropriate error code, description, and server message details
 */
+ (instancetype)errorWithHTTPStatusCode:(NSInteger)httpStatusCode serverMessage:(nullable NSString *)serverMessage;

/**
 * Creates an error with the specified CloudX error code and user info
 * @param code The CloudX error code
 * @param userInfo Additional user info dictionary
 * @return A new CLXError instance
 */
+ (instancetype)errorWithCode:(CLXErrorCode)code userInfo:(nullable NSDictionary *)userInfo;

/**
 * Initializes an error with the specified CloudX error code
 * @param code The CloudX error code
 * @return An initialized CLXError instance
 */
- (instancetype)initWithCode:(CLXErrorCode)code;

/**
 * Initializes an error with the specified CloudX error code and user info
 * @param code The CloudX error code
 * @param userInfo Additional user info dictionary
 * @return An initialized CLXError instance
 */
- (instancetype)initWithCode:(CLXErrorCode)code userInfo:(nullable NSDictionary *)userInfo;

/**
 * The underlying error that caused this error, if any
 * @return The original error or nil if none was provided
 * @discussion Accessible via userInfo[NSUnderlyingErrorKey] per standard NSError patterns
 */
@property (nonatomic, readonly, nullable) NSError *underlyingError;

/**
 * Returns the string name for a CLXErrorCode, matching Android's CloudXErrorCode.name
 */
+ (NSString *)nameForCode:(CLXErrorCode)code;

@end

/**
 * NSError category for enhanced error message formatting
 */
@interface NSError (CLXErrorFormatting)

/**
 * Returns a comprehensive error message including both localizedDescription and localizedFailureReason
 * @return Combined error message with server details if available
 */
- (NSString *)clx_fullErrorMessage;

@end

NS_ASSUME_NONNULL_END
