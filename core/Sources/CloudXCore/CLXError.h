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
 * CloudX SDK error codes - following industry standards
 *
 * Error code ranges:
 * 100-199: Network and connectivity errors
 * 200-299: SDK initialization errors
 * 300-399: Ad request and loading errors
 * 400-499: Ad display and presentation errors
 * 500-599: Configuration and setup errors
 */
typedef NS_ENUM(NSInteger, CLXErrorCode) {
    // GENERAL ERRORS (0-99)
    /// An internal error occurred
    CLXErrorCodeInternalError = 0,

    // NETWORK ERRORS (100-199)
    /// Network error
    CLXErrorCodeNetworkError = 100,
    /// Network request timed out
    CLXErrorCodeNetworkTimeout = 101,
    /// Server error (5xx)
    CLXErrorCodeServerError = 102,
    /// Client error (4xx)
    CLXErrorCodeClientError = 103,
    /// Rate limited (429)
    CLXErrorCodeTooManyRequests = 104,
    /// Invalid or unparseable server response
    CLXErrorCodeInvalidResponse = 105,
    /// No network connectivity
    CLXErrorCodeNoConnection = 106,

    // INITIALIZATION ERRORS (200-299)
    /// SDK failed to initialize
    CLXErrorCodeNotInitialized = 200,
    /// SDK initialized but no adapters were found
    CLXErrorCodeNoAdaptersFound = 201,
    /// No ad networks configured for this app
    CLXErrorCodeNoNetworksConfigured = 202,
    /// Invalid app key provided during initialization
    CLXErrorCodeInvalidAppKey = 203,
    /// SDK disabled by kill switch
    CLXErrorCodeSDKDisabled = 204,
    
    // AD REQUEST/LOADING ERRORS (300-399)
    /// Ad unit not found or invalid
    CLXErrorCodeInvalidAdUnit = 300,
    /// Ads disabled for this ad unit
    CLXErrorCodeAdsDisabled = 301,
    /// No ad fill available (no ads to show)
    CLXErrorCodeNoFill = 302,
    /// Ad failed to load for unknown reasons
    CLXErrorCodeLoadFailed = 304,
    
    // AD DISPLAY/SHOW ERRORS (400-499)
    /// Ad not ready
    CLXErrorCodeAdNotReady = 400,
    /// Ad already showing
    CLXErrorCodeAdAlreadyShowing = 401,
    
    // CONFIGURATION/SETUP ERRORS (500-599)
    /// Native view is nil or invalid
    CLXErrorCodeInvalidNativeView = 500,
    
    // ADAPTER ERRORS (600-699)
    /// Internal adapter error
    CLXErrorCodeAdapterInternalError = 600,
    /// Ad network adapter could not fill the ad request - no inventory available
    CLXErrorCodeAdapterNoFill = 601,
    /// Ad network adapter is in an invalid state for loading ads
    CLXErrorCodeAdapterInvalidLoadState = 602,
    /// Ad network adapter has invalid or missing configuration
    CLXErrorCodeAdapterInvalidConfiguration = 603,
    /// Ad network adapter received invalid server parameters (e.g., missing placement ID)
    CLXErrorCodeAdapterInvalidServerExtras = 604,
    /// Bad request to ad network
    CLXErrorCodeAdapterBadRequest = 605,
    /// Ad network adapter not initialized
    CLXErrorCodeAdapterNotInitialized = 606,
    /// Ad network adapter initialization failed
    CLXErrorCodeAdapterInitializationError = 607,
    /// Ad not ready to be shown
    CLXErrorCodeAdapterAdNotReady = 608,
    /// Adapter load timed out
    CLXErrorCodeAdapterLoadTimeout = 609,
    /// Ad network adapter request timed out
    CLXErrorCodeAdapterTimeout = 610,
    /// Ad network adapter failed to establish connection with ad server
    CLXErrorCodeAdapterNoConnection = 611,
    /// Ad network server returned an error response
    CLXErrorCodeAdapterServerError = 612,
    /// Bid token collection timed out
    CLXErrorCodeAdapterBidTokenTimeout = 613,
    /// Bid token collection not supported
    CLXErrorCodeAdapterBidTokenNotSupported = 614,
    /// WebView error in adapter
    CLXErrorCodeAdapterWebViewError = 615,
    /// Ad expired before being shown
    CLXErrorCodeAdapterAdExpired = 616,
    /// Ad frequency capped
    CLXErrorCodeAdapterAdFrequencyCapped = 617,
    /// Reward error in adapter
    CLXErrorCodeAdapterRewardError = 618,
    /// Missing required native ad assets
    CLXErrorCodeAdapterMissingNativeAdAssets = 619,
    /// Missing view controller required for ad display
    CLXErrorCodeAdapterMissingViewController = 620,
    /// Ad display failed
    CLXErrorCodeAdapterDisplayFailed = 621
};

/**
 * CloudX SDK error domain
 */
extern NSString * const CLXErrorDomain;

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
