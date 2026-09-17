#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

@class BigoAdError;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoErrorHandler
 * @brief Maps BIGO Ads SDK errors to CloudX adapter errors.
 */
@interface CLXBigoErrorHandler : NSObject

/**
 * @brief Converts a BIGO Ads SDK error to a CLXError with the matching adapter error code.
 * @discussion The partner error code, sub code and message are preserved on the underlying
 *             NSError for debugging.
 * @param bigoError The error from the BIGO Ads SDK; nil maps to an internal adapter error.
 * @return CLXError with the mapped adapter error code.
 */
+ (CLXError *)toCloudXError:(nullable BigoAdError *)bigoError;

/**
 * @brief The CloudX error code for a BIGO Ads SDK error code.
 * @param bigoErrorCode A `BIGO_AD_ERROR_CODE_*` value.
 * @return The mapped CloudX error code.
 */
+ (CLXErrorCode)cloudXErrorCodeForBigoErrorCode:(NSInteger)bigoErrorCode;

@end

NS_ASSUME_NONNULL_END
