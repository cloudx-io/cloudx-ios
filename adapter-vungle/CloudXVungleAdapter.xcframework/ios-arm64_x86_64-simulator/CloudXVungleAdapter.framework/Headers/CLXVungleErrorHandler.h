//
//  CLXVungleErrorHandler.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps Vungle SDK errors to CloudX adapter errors.
 */
@interface CLXVungleErrorHandler : NSObject

/**
 * Converts a Vungle SDK error to a CLXError with appropriate adapter error code.
 * Preserves the original Vungle error as underlying error for debugging.
 *
 * @param vungleError The NSError from Vungle SDK
 * @param isShowError YES if the error occurred during ad presentation, NO for load errors.
 *        This affects mapping for certain error codes (e.g., VungleErrorAdNotLoaded).
 * @return CLXError with mapped adapter error code and original Vungle error as underlying error
 */
+ (CLXError *)toCloudXError:(NSError *)vungleError isShowError:(BOOL)isShowError;

@end

NS_ASSUME_NONNULL_END
