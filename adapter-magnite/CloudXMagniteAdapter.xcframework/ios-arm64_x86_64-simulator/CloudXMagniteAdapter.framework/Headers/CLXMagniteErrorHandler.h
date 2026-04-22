//
//  CLXMagniteErrorHandler.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps Magnite SDK errors to CloudX adapter errors.
 */
@interface CLXMagniteErrorHandler : NSObject

/**
 * Converts a Magnite SDK error to a CLXError with appropriate adapter error code.
 * Preserves the original Magnite error as underlying error for debugging.
 *
 * Only call with errors originating from the Magnite SDK. Adapter-constructed
 * CLXError objects already carry an intentional code and must be forwarded
 * to publishers directly, not through this helper.
 *
 * @param magniteError The NSError from the Magnite SDK.
 * @return CLXError with mapped adapter error code and original Magnite error as underlying error.
 */
+ (CLXError *)toCloudXError:(NSError *)magniteError;

@end

NS_ASSUME_NONNULL_END
