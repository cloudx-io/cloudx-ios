//
//  CLXVungleErrorHandler.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleErrorHandler.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

NSString * const CLXVungleAdapterErrorDomain = @"com.cloudx.adapter.vungle";

@implementation CLXVungleErrorHandler

+ (NSError *)handleVungleError:(NSError *)error
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(NSString *)placementID {
    
    if (!error) {
        return nil;
    }
    
    NSString *errorDescription = [self descriptionForErrorCode:error.code];
    NSString *logMessage = [NSString stringWithFormat:@"Vungle %@ Error - Placement: %@, Code: %ld, Description: %@, Original: %@",
                           context, placementID, (long)error.code, errorDescription, error.localizedDescription];
    
    [logger logError:logMessage];
    
    // Map to CloudX error and add metadata
    NSError *mappedError = [self mapVungleError:error context:context];
    
    // Add retry and rate limiting metadata
    NSMutableDictionary *userInfo = [mappedError.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    userInfo[@"original_error"] = error;
    userInfo[@"placement_id"] = placementID;
    userInfo[@"context"] = context;
    userInfo[@"is_retryable"] = @([self isRetryableError:error]);
    userInfo[@"suggested_delay"] = @([self suggestedDelayForError:error]);
    userInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
    
    return [NSError errorWithDomain:mappedError.domain
                               code:mappedError.code
                           userInfo:[userInfo copy]];
}

+ (NSError *)mapVungleError:(NSError *)vungleError context:(NSString *)context {
    if (!vungleError) {
        return nil;
    }
    
    CLXVungleAdapterErrorCode mappedCode;
    NSString *description;
    
    // Map Vungle error codes to CloudX error codes
    // Note: Vungle SDK error codes may vary, this mapping covers common scenarios
    switch (vungleError.code) {
        case 10001: // VungleSDKErrorNoFill
            mappedCode = CLXVungleAdapterErrorCodeNoFill;
            description = @"No ad available to show";
            break;
            
        case 10002: // VungleSDKErrorNetworkError
            mappedCode = CLXVungleAdapterErrorCodeNetworkError;
            description = @"Network connection error";
            break;
            
        case 10003: // VungleSDKErrorInvalidPlacement
            mappedCode = CLXVungleAdapterErrorCodeInvalidPlacement;
            description = @"Invalid placement ID";
            break;
            
        case 10004: // VungleSDKErrorNotInitialized
            mappedCode = CLXVungleAdapterErrorCodeNotInitialized;
            description = @"Vungle SDK not initialized";
            break;
            
        case 10005: // VungleSDKErrorAdExpired
            mappedCode = CLXVungleAdapterErrorCodeAdExpired;
            description = @"Ad has expired";
            break;
            
        case 10006: // VungleSDKErrorTimeout
            mappedCode = CLXVungleAdapterErrorCodeTimeout;
            description = @"Request timed out";
            break;
            
        default:
            mappedCode = CLXVungleAdapterErrorCodeLoadFailed;
            description = vungleError.localizedDescription ?: @"Unknown Vungle SDK error";
            break;
    }
    
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Vungle %@ error: %@", context, description],
        @"vungle_error_code": @(vungleError.code),
        @"vungle_error_domain": vungleError.domain ?: @"unknown"
    };
    
    return [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                               code:mappedCode
                           userInfo:userInfo];
}

+ (NSTimeInterval)suggestedDelayForError:(NSError *)error {
    if (!error) {
        return 0;
    }
    
    // Check if this is a rate limiting error
    if ([error.domain isEqualToString:CLXVungleAdapterErrorDomain]) {
        switch (error.code) {
            case CLXVungleAdapterErrorCodeNetworkError:
                return 5.0; // 5 second delay for network errors
                
            case CLXVungleAdapterErrorCodeTimeout:
                return 10.0; // 10 second delay for timeouts
                
            case CLXVungleAdapterErrorCodeNoFill:
                return 30.0; // 30 second delay for no fill
                
            default:
                return 0;
        }
    }
    
    // Check original Vungle error for rate limiting indicators
    NSError *originalError = error.userInfo[@"original_error"];
    if (originalError && [originalError.localizedDescription containsString:@"rate"]) {
        return 60.0; // 1 minute delay for rate limiting
    }
    
    return 0;
}

+ (BOOL)isRetryableError:(NSError *)error {
    if (!error) {
        return NO;
    }
    
    if ([error.domain isEqualToString:CLXVungleAdapterErrorDomain]) {
        switch (error.code) {
            case CLXVungleAdapterErrorCodeNetworkError:
            case CLXVungleAdapterErrorCodeTimeout:
            case CLXVungleAdapterErrorCodeNoFill:
                return YES;
                
            case CLXVungleAdapterErrorCodeInvalidConfiguration:
            case CLXVungleAdapterErrorCodeInvalidPlacement:
            case CLXVungleAdapterErrorCodeNotInitialized:
                return NO;
                
            default:
                return NO;
        }
    }
    
    return NO;
}

+ (NSString *)descriptionForErrorCode:(NSInteger)errorCode {
    switch (errorCode) {
        case 10001:
            return @"No Fill - No ad available for this request";
        case 10002:
            return @"Network Error - Unable to connect to Vungle servers";
        case 10003:
            return @"Invalid Placement - Placement ID not found or inactive";
        case 10004:
            return @"Not Initialized - Vungle SDK must be initialized before use";
        case 10005:
            return @"Ad Expired - The loaded ad has expired and cannot be shown";
        case 10006:
            return @"Timeout - Request timed out while loading ad";
        case 10007:
            return @"Invalid App ID - The provided App ID is invalid";
        case 10008:
            return @"Ad Already Loaded - An ad is already loaded for this placement";
        case 10009:
            return @"Ad Not Loaded - No ad is loaded for this placement";
        case 10010:
            return @"Internal Error - An internal error occurred in the Vungle SDK";
        default:
            return [NSString stringWithFormat:@"Unknown Error - Vungle SDK error code %ld", (long)errorCode];
    }
}

+ (NSDictionary *)userFriendlyAlertInfoForError:(NSError *)error context:(NSString *)context {
    NSString *title = @"Ad Unavailable";
    NSString *message = @"Unable to load advertisement at this time. Please try again later.";
    
    if ([error.domain isEqualToString:CLXVungleAdapterErrorDomain]) {
        switch (error.code) {
            case CLXVungleAdapterErrorCodeNoFill:
                title = @"No Ads Available";
                message = @"No advertisements are currently available. Please try again later.";
                break;
                
            case CLXVungleAdapterErrorCodeNetworkError:
                title = @"Connection Error";
                message = @"Unable to connect to the internet. Please check your connection and try again.";
                break;
                
            case CLXVungleAdapterErrorCodeTimeout:
                title = @"Request Timed Out";
                message = @"The request took too long to complete. Please try again.";
                break;
                
            case CLXVungleAdapterErrorCodeInvalidConfiguration:
            case CLXVungleAdapterErrorCodeInvalidPlacement:
                title = @"Configuration Error";
                message = @"There's a configuration issue. Please contact support if this persists.";
                break;
                
            default:
                title = @"Ad Error";
                message = @"An error occurred while loading the advertisement. Please try again.";
                break;
        }
    }
    
    return @{
        @"title": title,
        @"message": message
    };
}

@end
