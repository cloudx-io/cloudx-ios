//
// CLXError.h
// CloudXCore
//
// Industry-standard error codes following AppLovin MAX, Google Mobile Ads, and Unity Ads patterns
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Loss reasons following OpenRTB standard - matching Android LossReason enum
 * See: OpenRTB 2.5+ specification for standard loss reason codes
 */
typedef NS_ENUM(NSInteger, CLXLossReason) {
    CLXLossReasonBidWon = 0,              // Bid Won (OpenRTB: 0)
    CLXLossReasonInternalError = 1,       // Internal Error (OpenRTB: 1)
    CLXLossReasonLostToHigherBid = 102    // Lost to Higher Bid (OpenRTB: 102)
};

/**
 * CloudX SDK error codes - following industry standards
 * 
 * Error code ranges:
 * 100-199: SDK initialization errors
 * 200-299: Network and connectivity errors  
 * 300-399: Ad request and loading errors
 * 400-499: Ad display and presentation errors
 * 500-599: Configuration and setup errors
 */
typedef NS_ENUM(NSInteger, CLXErrorCode) {
    // GENERAL ERRORS (0-99)
    /// Unknown or unspecified error
    CLXErrorCodeUnknown = 0,
    
    // INITIALIZATION ERRORS (100-199)
    /// SDK failed to initialize
    CLXErrorCodeNotInitialized = 100,
    /// SDK initialization is already in progress
    CLXErrorCodeInitializationInProgress = 101,
    /// SDK initialized but no adapters were found
    CLXErrorCodeNoAdaptersFound = 102,
    /// SDK initialization timeout
    CLXErrorCodeInitializationTimeout = 103,
    /// Invalid app key provided during initialization
    CLXErrorCodeInvalidAppKey = 104,
    /// SDK disabled by kill switch
    CLXErrorCodeSDKDisabled = 105,
    
    // NETWORK ERRORS (200-299)
    /// Network connectivity issues
    CLXErrorCodeNetworkError = 200,
    /// Network timeout occurred
    CLXErrorCodeNetworkTimeout = 201,
    /// Invalid server response
    CLXErrorCodeInvalidResponse = 202,
    /// Server returned an error
    CLXErrorCodeServerError = 203,
    
    // AD REQUEST/LOADING ERRORS (300-399)
    /// No ad fill available (no ads to show)
    CLXErrorCodeNoFill = 300,
    /// Invalid ad request parameters
    CLXErrorCodeInvalidRequest = 301,
    /// Invalid placement ID
    CLXErrorCodeInvalidPlacement = 302,
    /// Ad loading timeout
    CLXErrorCodeLoadTimeout = 303,
    /// Ad failed to load for unknown reasons
    CLXErrorCodeLoadFailed = 304,
    /// Ad content is invalid or corrupted
    CLXErrorCodeInvalidAd = 305,
    /// Too many ad requests (rate limiting)
    CLXErrorCodeTooManyRequests = 306,
    /// Ad request was cancelled
    CLXErrorCodeRequestCancelled = 307,
    /// Ads disabled by kill switch
    CLXErrorCodeAdsDisabled = 308,
    
    // AD DISPLAY/SHOW ERRORS (400-499)
    /// Ad is not ready to be shown
    CLXErrorCodeAdNotReady = 400,
    /// Ad has already been shown
    CLXErrorCodeAdAlreadyShown = 401,
    /// Ad has expired and cannot be shown
    CLXErrorCodeAdExpired = 402,
    /// View controller required for ad display is nil
    CLXErrorCodeInvalidViewController = 403,
    /// Ad failed to show for unknown reasons
    CLXErrorCodeShowFailed = 404,
    
    // CONFIGURATION/SETUP ERRORS (500-599)
    /// Invalid ad unit configuration
    CLXErrorCodeInvalidAdUnit = 500,
    /// Required permissions not granted
    CLXErrorCodePermissionDenied = 501,
    /// Ad format not supported
    CLXErrorCodeUnsupportedAdFormat = 502,
    /// Banner view is nil or invalid
    CLXErrorCodeInvalidBannerView = 503,
    /// Native view is nil or invalid
    CLXErrorCodeInvalidNativeView = 504,
    /// No adapters registered (no adapter frameworks included in project)
    CLXErrorCodeNoAdaptersRegistered = 505,
    /// Invalid adapter configuration
    CLXErrorCodeInvalidConfiguration = 506,
    /// Invalid ad unit ID provided
    CLXErrorCodeInvalidAdUnitID = 507,
    /// Invalid bid response
    CLXErrorCodeInvalidBidResponse = 508
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
