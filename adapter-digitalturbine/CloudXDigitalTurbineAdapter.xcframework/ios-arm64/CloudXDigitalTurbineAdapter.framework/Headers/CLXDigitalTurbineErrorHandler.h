//
//  CLXDigitalTurbineErrorHandler.h
//  CloudXDigitalTurbineAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps Digital Turbine SDK errors to CloudX adapter errors.
 * Preserves the original error code and message as an underlying error for debugging.
 */
@interface CLXDigitalTurbineErrorHandler : NSObject

+ (CLXError *)toCloudXError:(nullable NSError *)sdkError;

@end

NS_ASSUME_NONNULL_END
