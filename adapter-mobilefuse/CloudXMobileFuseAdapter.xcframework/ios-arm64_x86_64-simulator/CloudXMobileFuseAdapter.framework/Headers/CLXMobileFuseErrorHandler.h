//
//  CLXMobileFuseErrorHandler.h
//  CloudXMobileFuseAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXError.h>)
#import <CloudXCore/CLXError.h>
#else
#import "CLXError.h"
#endif

@class MFAdError;

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps MobileFuse SDK errors to CloudX adapter errors.
 *
 * The MobileFuse SDK surfaces two kinds of errors:
 *  1. `MFAdError` instances delivered via -onAdError:withError: on the ad callback receiver.
 *  2. `NSError` produced inside the adapter for guard-clause failures (placement-ID missing, etc).
 *
 * Both shapes route through this handler so callers receive a uniform `CLXError`
 * with a stable `CLXErrorCode` and the original error preserved as underlyingError.
 */
@interface CLXMobileFuseErrorHandler : NSObject

/**
 * Converts an MFAdError (delivered on the SDK ad-callback receiver) to a CLXError.
 * Preserves the original code and message for downstream debugging.
 */
+ (CLXError *)toCloudXErrorFromAdError:(nullable MFAdError *)adError;

/**
 * Converts a generic NSError (e.g. from an SDK init/token call) to a CLXError.
 */
+ (CLXError *)toCloudXError:(nullable NSError *)error;

/**
 * Returns YES when the supplied MobileFuse error code represents a load-phase
 * failure (`AdAlreadyLoaded` / `AdLoadError`). Per the documented MobileFuse
 * error contract, every other code is a display-phase failure. Used by the
 * per-format adapters to route load-vs-display failures through the correct
 * delegate method.
 */
+ (BOOL)isLoadPhaseErrorCode:(NSInteger)code;

@end

NS_ASSUME_NONNULL_END
