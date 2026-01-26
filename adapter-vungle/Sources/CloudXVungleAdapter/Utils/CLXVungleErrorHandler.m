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
    
    [logger error:logMessage];
    
    // Map to CloudX error and add metadata
    NSError *mappedError = [self mapVungleError:error context:context];
    
    // Add metadata
    NSMutableDictionary *userInfo = [mappedError.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    userInfo[@"original_error"] = error;
    userInfo[@"placement_id"] = placementID;
    userInfo[@"context"] = context;
    userInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
    
    return [NSError errorWithDomain:mappedError.domain
                               code:mappedError.code
                           userInfo:userInfo];
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

@end
