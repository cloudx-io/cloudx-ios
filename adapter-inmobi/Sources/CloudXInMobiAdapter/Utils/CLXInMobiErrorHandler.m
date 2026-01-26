//
//  CLXInMobiErrorHandler.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "CLXInMobiErrorHandler.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

@implementation CLXInMobiErrorHandler

+ (NSError *)handleInMobiError:(NSError *)error
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(NSString *)placementID {
    
    if (!error) {
        return [CLXError errorWithCode:CLXErrorCodeLoadFailed
                           description:@"Unknown error occurred"];
    }
    
    // Map InMobi error code to CloudX error code
    CLXErrorCode clxCode = [self mapInMobiErrorCode:error.code];
    
    // Create enhanced error description
    NSString *errorDescription = [NSString stringWithFormat:
                                 @"InMobi %@ error for placement %@: %@ (Code: %ld)",
                                 context, placementID, error.localizedDescription ?: @"Unknown error", (long)error.code];
    
    // Log the error
    [logger error:errorDescription];

    // Create CloudX error
    return [CLXError errorWithCode:clxCode description:errorDescription];
}

+ (CLXErrorCode)mapInMobiErrorCode:(NSInteger)inMobiCode {
    // InMobi error codes (from IMRequestStatus)
    // 0: kIMStatusCodeNetworkUnReachable
    // 1: kIMStatusCodeNoFill
    // 2: kIMStatusCodeRequestInvalid
    // 3: kIMStatusCodeRequestPending
    // 4: kIMStatusCodeRequestTimedOut
    // 5: kIMStatusCodeInternalError
    // 6: kIMStatusCodeServerError
    // 7: kIMStatusCodeAdActive
    // 8: kIMStatusCodeEarlyRefreshRequest
    // 9: kIMStatusCodeNoNetworkConnection
    // 10: kIMStatusCodeNativeNotReady
    // 11: kIMStatusCodeDroppedBySDK
    
    switch (inMobiCode) {
        case 0:  // Network unreachable
        case 9:  // No network connection
            return CLXErrorCodeNetworkError;
            
        case 1:  // No fill
            return CLXErrorCodeNoFill;
            
        case 2:  // Invalid request
            return CLXErrorCodeInvalidAdUnit;
            
        case 4:  // Timeout
            return CLXErrorCodeAdapterTimeout;
            
        case 10: // Native not ready
        case 7:  // Ad active
            return CLXErrorCodeAdNotReady;
            
        case 3:  // Request pending
        case 5:  // Internal error
        case 6:  // Server error
        case 8:  // Early refresh
        case 11: // Dropped by SDK
        default:
            return CLXErrorCodeLoadFailed;
    }
}

@end

