//
//  CLXMetaErrorHandler.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps Meta Audience Network errors to CloudX adapter errors.
 */
@interface CLXMetaErrorHandler : NSObject

/**
 * Converts a Meta FAN SDK error to a CLXError with appropriate adapter error code.
 * Preserves the original Meta error code and message for debugging.
 *
 * @param metaError The NSError from Meta FAN SDK
 * @return CLXError with mapped adapter error code and original Meta error as underlying error
 */
+ (CLXError *)toCloudXError:(NSError *)metaError;

@end

NS_ASSUME_NONNULL_END
