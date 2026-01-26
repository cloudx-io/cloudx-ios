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

    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: %@ (code: %ld)",
                   context, placementID ?: @"N/A", description, (long)molocoError.code]];
    
    // Map Moloco-specific errors to CloudX errors
    // Note: These error codes are based on common ad network patterns
    // Update based on actual Moloco SDK error codes from documentation
    switch (molocoError.code) {
        case 1001: // Example: No fill error
            cloudXCode = CLXErrorCodeNoFill;
            description = @"No ad available";
            break;
            
        case 1002: // Example: Network error
            cloudXCode = CLXErrorCodeNetworkError;
            description = @"Network connectivity issue";
            recoverySuggestion = @"Check internet connection and try again";
            break;
            
        case 1003: // Example: Invalid placement
            cloudXCode = CLXErrorCodeAdapterInvalidServerExtras;
            description = @"Invalid placement ID";
            recoverySuggestion = @"Verify placement ID is correct";
            break;
            
        case 1004: // Example: Ad not ready
            cloudXCode = CLXErrorCodeAdNotReady;
            description = @"Ad not ready to show";
            break;
            
        case 1005: // Example: SDK not initialized
            cloudXCode = CLXErrorCodeLoadFailed;
            description = @"Moloco SDK not initialized";
            recoverySuggestion = @"Initialize Moloco SDK before loading ads";
            break;
            
        case 1006: // Example: Invalid configuration
            cloudXCode = CLXErrorCodeAdapterInvalidConfiguration;
            description = @"Invalid SDK configuration";
            break;
            
        case 1007: // Example: Timeout
            cloudXCode = CLXErrorCodeTimeout;
            description = @"Ad request timeout";
            break;
            
        default:
            cloudXCode = CLXErrorCodeInternalError;
            description = [NSString stringWithFormat:@"Moloco error: %@", molocoError.localizedDescription];
            break;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{
        NSUnderlyingErrorKey: molocoError
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

