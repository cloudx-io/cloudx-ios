//
//  CLXPrebidError.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 error handling and constants
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const CLXPrebidErrorDomain;

/**
 * Prebid adapter error codes
 * Aligned with Prebid 3.0 error specifications
 */
typedef NS_ENUM(NSInteger, CLXPrebidErrorCode) {
    CLXPrebidErrorCodeUnknown = 0,
    
    // Configuration Errors (1xx)
    CLXPrebidErrorCodeNotInitialized = 100,
    CLXPrebidErrorCodeInvalidConfiguration = 101,
    CLXPrebidErrorCodeInvalidPrebidServerURL = 102,
    
    // Network Errors (2xx)
    CLXPrebidErrorCodeNetworkFailure = 200,
    CLXPrebidErrorCodeRequestTimeout = 201,
    CLXPrebidErrorCodeInvalidResponse = 202,
    CLXPrebidErrorCodeServerError = 203,
    
    // Bid Errors (3xx)
    CLXPrebidErrorCodeNoBidResponse = 300,
    CLXPrebidErrorCodeInvalidBidResponse = 301,
    CLXPrebidErrorCodeBidExpired = 302,
    CLXPrebidErrorCodeInsufficientInventory = 303,
    
    // Rendering Errors (4xx)
    CLXPrebidErrorCodeRenderingFailure = 400,
    CLXPrebidErrorCodeInvalidAdMarkup = 401,
    CLXPrebidErrorCodeWebViewError = 402,
    CLXPrebidErrorCodeViewControllerNotAvailable = 403,
    
    // Ad Format Errors (5xx)
    CLXPrebidErrorCodeUnsupportedAdFormat = 500,
    CLXPrebidErrorCodeInvalidAdSize = 501,
    CLXPrebidErrorCodeVideoPlaybackError = 502,
    CLXPrebidErrorCodeNativeAdError = 503
};

/**
 * Utility class for creating and managing Prebid-specific errors
 */
@interface CLXPrebidError : NSObject

/**
 * Create error with code and description
 * @param code Error code from CLXPrebidErrorCode
 * @param description User-readable error description
 * @return NSError instance with Prebid domain
 */
+ (NSError *)errorWithCode:(CLXPrebidErrorCode)code description:(NSString *)description;

/**
 * Create error with code, description and underlying error
 * @param code Error code from CLXPrebidErrorCode
 * @param description User-readable error description
 * @param underlyingError Original error that caused this error
 * @return NSError instance with Prebid domain and underlying error
 */
+ (NSError *)errorWithCode:(CLXPrebidErrorCode)code 
               description:(NSString *)description 
           underlyingError:(nullable NSError *)underlyingError;

/**
 * Get human-readable description for error code
 * @param code Error code
 * @return Description string
 */
+ (NSString *)descriptionForCode:(CLXPrebidErrorCode)code;

/**
 * Check if error is a network-related error
 * @param error Error to check
 * @return YES if error is network-related
 */
+ (BOOL)isNetworkError:(NSError *)error;

/**
 * Check if error is a rendering-related error
 * @param error Error to check
 * @return YES if error is rendering-related
 */
+ (BOOL)isRenderingError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END