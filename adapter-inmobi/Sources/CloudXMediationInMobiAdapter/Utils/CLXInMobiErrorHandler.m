//
//  CLXInMobiErrorHandler.m
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiErrorHandler.h>
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
    
    // Check for retry recommendation
    BOOL shouldRetry = [self shouldRetryForError:error];
    NSTimeInterval retryDelay = [self retryDelayForError:error];
    
    if (shouldRetry) {
        [logger info:[NSString stringWithFormat:@"Retry recommended after %.0f seconds", retryDelay]];
    }
    
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
            return CLXErrorCodeInvalidConfig;
            
        case 4:  // Timeout
            return CLXErrorCodeTimeout;
            
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

+ (BOOL)shouldRetryForError:(NSError *)error {
    if (!error) return NO;
    
    NSInteger code = error.code;
    
    // Retry on network errors, timeouts, server errors, no fill
    switch (code) {
        case 0:  // Network unreachable
        case 1:  // No fill
        case 4:  // Timeout
        case 5:  // Internal error
        case 6:  // Server error
        case 8:  // Early refresh
        case 9:  // No network connection
        case 11: // Dropped by SDK
            return YES;
            
        case 2:  // Invalid request
        case 3:  // Request pending
        case 7:  // Ad active
        case 10: // Native not ready
        default:
            return NO;
    }
}

+ (NSTimeInterval)retryDelayForError:(NSError *)error {
    if (!error) return 0;
    
    NSInteger code = error.code;
    
    switch (code) {
        case 0:  // Network unreachable
        case 9:  // No network connection
            return 5.0;  // 5 seconds for network errors
            
        case 1:  // No fill
            return 30.0; // 30 seconds for no fill
            
        case 4:  // Timeout
            return 10.0; // 10 seconds for timeout
            
        case 5:  // Internal error
        case 11: // Dropped by SDK
            return 10.0; // 10 seconds for internal errors
            
        case 6:  // Server error
            return 15.0; // 15 seconds for server errors
            
        case 8:  // Early refresh
            return 5.0;  // 5 seconds for early refresh
            
        default:
            return 0;
    }
}

@end

