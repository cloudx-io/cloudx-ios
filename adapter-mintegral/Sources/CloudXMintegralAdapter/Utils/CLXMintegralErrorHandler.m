#import "CLXMintegralErrorHandler.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>
#import <MTGSDK/MTGSDK.h>

// Mintegral SDK Error Codes (from MTGErrorCode)
// These are the actual error codes returned by Mintegral SDK
typedef NS_ENUM(NSInteger, MTGErrorCode) {
    MTGErrorCodeNoAdsAvailable = 3001,          // No ads available
    MTGErrorCodeNetworkError = 3002,            // Network error
    MTGErrorCodeLoadTimeout = 3003,             // Load timeout
    MTGErrorCodeEmptyUnitId = 3004,             // Empty unit ID
    MTGErrorCodeEmptyPlacementId = 3005,        // Empty placement ID
    MTGErrorCodeInvalidPlacementId = 3006,      // Invalid placement ID
    MTGErrorCodeAdShowFailed = 3007,            // Ad show failed
    MTGErrorCodeSDKNotInitialized = 3008,       // SDK not initialized
    MTGErrorCodeInvalidBidToken = 3009,         // Invalid bid token
    MTGErrorCodeFrequencyCap = 3010,            // Frequency cap reached
    MTGErrorCodeVideoLoadFailed = 3011,         // Video load failed
    MTGErrorCodeAdAlreadyLoaded = 3012,         // Ad already loaded
    MTGErrorCodeServerError = 3013,             // Server error
    MTGErrorCodeInternalError = 3014,           // Internal SDK error
};

@implementation CLXMintegralErrorHandler

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID {
    
    CLXErrorCode cloudXCode = CLXErrorCodeUnknown;
    NSString *description = networkError.localizedDescription ?: @"Unknown error";
    NSString *recoverySuggestion = nil;
    BOOL shouldRetry = NO;
    
    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: %@",
                   context, placementID ?: @"N/A", description]];
    
    // Map Mintegral-specific errors to CloudX errors
    switch (networkError.code) {
        case MTGErrorCodeNoAdsAvailable:
            cloudXCode = CLXErrorCodeNoFill;
            description = @"No fill for ad request from Mintegral";
            recoverySuggestion = @"Try again later or check placement configuration";
            shouldRetry = YES;
            break;
            
        case MTGErrorCodeNetworkError:
            cloudXCode = CLXErrorCodeNetworkError;
            description = @"Mintegral network connectivity issue";
            recoverySuggestion = @"Check internet connection and try again";
            shouldRetry = YES;
            break;
            
        case MTGErrorCodeLoadTimeout:
            cloudXCode = CLXErrorCodeTimeout;
            description = @"Mintegral ad request timed out";
            recoverySuggestion = @"Try again";
            shouldRetry = YES;
            break;
            
        case MTGErrorCodeEmptyUnitId:
        case MTGErrorCodeEmptyPlacementId:
        case MTGErrorCodeInvalidPlacementId:
            cloudXCode = CLXErrorCodeInvalidAdUnitID;
            description = @"Invalid or empty Mintegral placement/unit ID";
            recoverySuggestion = @"Verify placement and unit IDs in dashboard";
            shouldRetry = NO;
            break;
            
        case MTGErrorCodeAdShowFailed:
            cloudXCode = CLXErrorCodePresentationError;
            description = @"Mintegral ad show failed";
            recoverySuggestion = @"Ensure ad is loaded before showing";
            shouldRetry = NO;
            break;
            
        case MTGErrorCodeSDKNotInitialized:
            cloudXCode = CLXErrorCodeNotInitialized;
            description = @"Mintegral SDK not initialized";
            recoverySuggestion = @"Initialize SDK before loading ads";
            shouldRetry = NO;
            break;
            
        case MTGErrorCodeInvalidBidToken:
            cloudXCode = CLXErrorCodeInvalidBidResponse;
            description = @"Invalid bid token for Mintegral";
            recoverySuggestion = @"Request a new bid token";
            shouldRetry = YES;
            break;
            
        case MTGErrorCodeFrequencyCap:
            cloudXCode = CLXErrorCodeRateLimit;
            description = @"Mintegral frequency cap reached";
            recoverySuggestion = @"Wait before requesting more ads";
            shouldRetry = NO;
            break;
            
        case MTGErrorCodeVideoLoadFailed:
            cloudXCode = CLXErrorCodeLoadFailed;
            description = @"Mintegral video load failed";
            recoverySuggestion = @"Check network and try again";
            shouldRetry = YES;
            break;
            
        case MTGErrorCodeAdAlreadyLoaded:
            cloudXCode = CLXErrorCodeLoadFailed;
            description = @"Mintegral ad already loaded";
            recoverySuggestion = @"Show current ad or wait before loading next";
            shouldRetry = NO;
            break;
            
        case MTGErrorCodeServerError:
            cloudXCode = CLXErrorCodeServerError;
            description = @"Mintegral server error";
            recoverySuggestion = @"Try again later";
            shouldRetry = YES;
            break;
            
        case MTGErrorCodeInternalError:
            cloudXCode = CLXErrorCodeInternalError;
            description = @"Mintegral SDK internal error";
            recoverySuggestion = @"Contact support if this persists";
            shouldRetry = NO;
            break;
            
        default:
            cloudXCode = CLXErrorCodeUnknown;
            description = [NSString stringWithFormat:@"Unknown Mintegral error: %ld - %@", 
                          (long)networkError.code, networkError.localizedDescription];
            recoverySuggestion = @"Check Mintegral SDK documentation for error code";
            shouldRetry = NO;
            break;
    }
    
    return [CLXError errorWithCode:cloudXCode
                       description:description
                recoverySuggestion:recoverySuggestion
                          userInfo:@{
                              NSUnderlyingErrorKey: networkError,
                              @"ShouldRetry": @(shouldRetry)
                          }];
}

@end

