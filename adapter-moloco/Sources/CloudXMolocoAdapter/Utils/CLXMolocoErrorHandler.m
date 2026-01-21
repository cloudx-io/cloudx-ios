//
//  CLXMolocoErrorHandler.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoErrorHandler.h>)
#import <CloudXMolocoAdapter/CLXMolocoErrorHandler.h>
#else
#import "CLXMolocoErrorHandler.h"
#endif

#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXMolocoErrorHandler

+ (NSError *)handleMolocoError:(NSError *)molocoError
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(nullable NSString *)placementID {
    
    CLXErrorCode cloudXCode = CLXErrorCodeInternalError;
    NSString *description = molocoError.localizedDescription ?: @"Unknown error";
    NSString *recoverySuggestion = nil;
    BOOL shouldRetry = NO;
    
    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: %@ (code: %ld)", 
                   context, placementID ?: @"N/A", description, (long)molocoError.code]];
    
    // Map Moloco-specific errors to CloudX errors
    // Note: These error codes are based on common ad network patterns
    // Update based on actual Moloco SDK error codes from documentation
    switch (molocoError.code) {
        case 1001: // Example: No fill error
            cloudXCode = CLXErrorCodeNoFill;
            description = @"No ad available";
            shouldRetry = YES;
            break;
            
        case 1002: // Example: Network error
            cloudXCode = CLXErrorCodeNetworkError;
            description = @"Network connectivity issue";
            recoverySuggestion = @"Check internet connection and try again";
            shouldRetry = YES;
            break;
            
        case 1003: // Example: Invalid placement
            cloudXCode = CLXErrorCodeInvalidAdUnitID;
            description = @"Invalid placement ID";
            recoverySuggestion = @"Verify placement ID is correct";
            shouldRetry = NO;
            break;
            
        case 1004: // Example: Ad not ready
            cloudXCode = CLXErrorCodeAdNotReady;
            description = @"Ad not ready to show";
            shouldRetry = NO;
            break;
            
        case 1005: // Example: SDK not initialized
            cloudXCode = CLXErrorCodeLoadFailed;
            description = @"Moloco SDK not initialized";
            recoverySuggestion = @"Initialize Moloco SDK before loading ads";
            shouldRetry = NO;
            break;
            
        case 1006: // Example: Invalid configuration
            cloudXCode = CLXErrorCodeInvalidConfiguration;
            description = @"Invalid SDK configuration";
            shouldRetry = NO;
            break;
            
        case 1007: // Example: Timeout
            cloudXCode = CLXErrorCodeTimeout;
            description = @"Ad request timeout";
            shouldRetry = YES;
            break;
            
        default:
            cloudXCode = CLXErrorCodeInternalError;
            description = [NSString stringWithFormat:@"Moloco error: %@", molocoError.localizedDescription];
            break;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{
        NSUnderlyingErrorKey: molocoError,
        @"ShouldRetry": @(shouldRetry)
    }];
    
    if (recoverySuggestion) {
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion;
    }
    
    return [CLXError errorWithCode:cloudXCode
                       description:description
                recoverySuggestion:recoverySuggestion
                          userInfo:userInfo];
}

@end

