#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps Mintegral SDK errors to CloudX adapter errors.
 */
@interface CLXMintegralErrorHandler : NSObject

/**
 * Converts a Mintegral SDK error to a CLXError with appropriate adapter error code.
 * Preserves the original Mintegral error code and message for debugging.
 *
 * @param mintegralError The NSError from Mintegral SDK
 * @return CLXError with mapped adapter error code and original Mintegral error as underlying error
 */
+ (CLXError *)toCloudXError:(NSError *)mintegralError;

@end

NS_ASSUME_NONNULL_END

