//
//  CLXRendererError.h
//  CloudXRenderer
//
//  CloudX renderer error handling and constants
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const CLXRendererErrorDomain;

/**
 * Renderer error codes
 */
typedef NS_ENUM(NSInteger, CLXRendererErrorCode) {
    CLXRendererErrorCodeUnknown = 0,
    
    // Configuration Errors (1xx)
    CLXRendererErrorCodeNotInitialized = 100,
    CLXRendererErrorCodeInvalidConfiguration = 101,
    CLXRendererErrorCodeInvalidServerURL = 102,
    
    // Network Errors (2xx)
    CLXRendererErrorCodeNetworkFailure = 200,
    CLXRendererErrorCodeRequestTimeout = 201,
    CLXRendererErrorCodeInvalidResponse = 202,
    CLXRendererErrorCodeServerError = 203,
    
    // Bid Errors (3xx)
    CLXRendererErrorCodeNoBidResponse = 300,
    CLXRendererErrorCodeInvalidBidResponse = 301,
    CLXRendererErrorCodeBidExpired = 302,
    CLXRendererErrorCodeInsufficientInventory = 303,
    
    // Rendering Errors (4xx)
    CLXRendererErrorCodeRenderingFailure = 400,
    CLXRendererErrorCodeInvalidAdMarkup = 401,
    CLXRendererErrorCodeWebViewError = 402,
    CLXRendererErrorCodeViewControllerNotAvailable = 403,
    
    // Ad Format Errors (5xx)
    CLXRendererErrorCodeUnsupportedAdFormat = 500,
    CLXRendererErrorCodeInvalidAdSize = 501,
    CLXRendererErrorCodeVideoPlaybackError = 502,
    CLXRendererErrorCodeNativeAdError = 503
};

/**
 * Utility class for creating and managing renderer-specific errors
 */
@interface CLXRendererError : NSObject

/**
 * Create error with code and description
 * @param code Error code from CLXRendererErrorCode
 * @param description User-readable error description
 * @return NSError instance with renderer domain
 */
+ (NSError *)errorWithCode:(CLXRendererErrorCode)code description:(NSString *)description;

/**
 * Create error with code, description and underlying error
 * @param code Error code from CLXRendererErrorCode
 * @param description User-readable error description
 * @param underlyingError Original error that caused this error
 * @return NSError instance with renderer domain and underlying error
 */
+ (NSError *)errorWithCode:(CLXRendererErrorCode)code 
               description:(NSString *)description 
           underlyingError:(nullable NSError *)underlyingError;

/**
 * Get human-readable description for error code
 * @param code Error code
 * @return Description string
 */
+ (NSString *)descriptionForCode:(CLXRendererErrorCode)code;

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