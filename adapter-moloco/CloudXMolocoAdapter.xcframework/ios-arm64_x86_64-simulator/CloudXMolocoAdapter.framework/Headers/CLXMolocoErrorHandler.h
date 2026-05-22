//
//  CLXMolocoErrorHandler.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps Moloco SDK errors to CloudX adapter errors.
 */
@interface CLXMolocoErrorHandler : NSObject

/**
 * Converts a Moloco SDK error to a CLXError with appropriate adapter error code.
 * Preserves the original Moloco error as underlying error for debugging.
 *
 * @param molocoError The NSError from Moloco SDK (domain MolocoSDK.MolocoError)
 * @param isShowError YES if the error occurred during ad presentation, NO for load errors.
 *        Affects mapping for ambiguous codes (e.g., "ad not loaded" presented during show
 *        becomes adNotReady; during load becomes invalidLoadState).
 * @return CLXError with mapped adapter error code and original Moloco error as underlying error
 */
+ (CLXError *)toCloudXError:(nullable NSError *)molocoError isShowError:(BOOL)isShowError;

@end

NS_ASSUME_NONNULL_END
