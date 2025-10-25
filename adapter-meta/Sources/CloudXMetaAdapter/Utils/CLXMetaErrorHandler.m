//
//  CLXMetaErrorHandler.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import "CLXMetaErrorHandler.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

// Meta FAN SDK Error Codes - Comprehensive List
typedef NS_ENUM(NSInteger, CLXMetaErrorCode) {
    // Network and Connectivity Errors
    CLXMetaErrorCodeNetworkError = 1000,
    
    // Ad Availability Errors
    CLXMetaErrorCodeNoFill = 1001,
    CLXMetaErrorCodeAdLoadTooFrequently = 1002,
    
    // Configuration and Setup Errors
    CLXMetaErrorCodeDisplayFormatMismatch = 1011,
    CLXMetaErrorCodeUnsupportedSDKVersion = 1012,
    
    // Authentication and Permission Errors
    CLXMetaErrorCodeNotAppAdminDeveloperOrTester = 1203,
    
    // Server-Side Errors
    CLXMetaErrorCodeServerError = 2000,
    CLXMetaErrorCodeInternalError = 2001,
    
    // Additional Error Codes (from Meta documentation)
    CLXMetaErrorCodeInvalidPlacement = 1004,
    CLXMetaErrorCodeAdAlreadyLoaded = 1005,
    CLXMetaErrorCodeAdNotLoaded = 1006,
    CLXMetaErrorCodeMediationError = 1007,
    CLXMetaErrorCodeBidTokenNotFound = 1008,
    CLXMetaErrorCodeInvalidBidToken = 1009,
    CLXMetaErrorCodeAdExpired = 1010,
    
    // Video-Specific Errors
    CLXMetaErrorCodeVideoPlaybackError = 1013,
    CLXMetaErrorCodeVideoNotAvailable = 1014,
    
    // Native Ad Specific Errors
    CLXMetaErrorCodeNativeAdNotRegistered = 1015,
    CLXMetaErrorCodeNativeAdViewNotFound = 1016,
    
    // Rewarded Video Specific Errors
    CLXMetaErrorCodeRewardedVideoNotReady = 1017,
    CLXMetaErrorCodeRewardedVideoAlreadyShown = 1018,
    
    // Privacy and Consent Errors
    CLXMetaErrorCodePrivacyConsentRequired = 1019,
    CLXMetaErrorCodeGDPRConsentRequired = 1020,
    
    // App Tracking Transparency (ATT) Errors
    CLXMetaErrorCodeATTNotDetermined = 1021,
    CLXMetaErrorCodeATTRestricted = 1022,
    CLXMetaErrorCodeATTDenied = 1023
};

@implementation CLXMetaErrorHandler

+ (NSError *)handleMetaError:(NSError *)error
                  withLogger:(CLXLogger *)logger
                     context:(NSString *)context
                 placementID:(NSString *)placementID {
    
    if (!error) {
        [logger error:[NSString stringWithFormat:@"❌ [CLXMetaErrorHandler] Null error passed to handler for %@", context]];
        return error;
    }
    
    // De-duplicate: Meta SDK sometimes calls error delegate twice from different internal layers
    static NSMutableDictionary *recentErrors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recentErrors = [NSMutableDictionary dictionary];
    });
    
    NSString *errorKey = [NSString stringWithFormat:@"%@_%@_%ld_%@", 
                          context, placementID ?: @"unknown", (long)error.code, error.domain];
    NSNumber *lastLogTime = recentErrors[errorKey];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    
    // If same error logged within 1 second, skip (Meta SDK duplicate)
    if (lastLogTime && (now - [lastLogTime doubleValue]) < 1.0) {
        return error; // Skip logging, just return enhanced error
    }
    recentErrors[errorKey] = @(now);
    
    NSInteger errorCode = error.code;
    NSString *errorDescription = [self descriptionForErrorCode:errorCode];
    NSString *originalMessage = error.localizedDescription ?: @"Unknown error";
    
    // Log comprehensive error details in a single line (includes user info inline if present)
    NSString *userInfoStr = (error.userInfo && error.userInfo.count > 0) ? 
                            [NSString stringWithFormat:@" | UserInfo: %@", error.userInfo] : @"";
    [logger error:[NSString stringWithFormat:@"❌ [CLXMetaErrorHandler] %@ Error - Code: %ld | %@ | Original: %@ | Placement: %@%@", 
                   context, (long)errorCode, errorDescription, originalMessage, placementID ?: @"Unknown", userInfoStr]];
    
    // Create enhanced error with additional metadata
    NSMutableDictionary *enhancedUserInfo = [error.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    
    // Add our custom metadata
    enhancedUserInfo[@"CLXMetaErrorDescription"] = errorDescription;
    enhancedUserInfo[@"CLXMetaContext"] = context;
    enhancedUserInfo[@"CLXMetaPlacementID"] = placementID ?: @"Unknown";
    enhancedUserInfo[@"CLXMetaIsRetryable"] = @([self isRetryableError:error]);
    
    // Add ATT status information for all Meta errors (helps with debugging)
    NSString *attStatusDesc = [self currentATTStatusDescription];
    enhancedUserInfo[@"CLXMetaATTStatusDescription"] = attStatusDesc;
    
    // Handle specific error codes with custom logic
    switch (errorCode) {
        case CLXMetaErrorCodeNoFill: {
            // Check ATT status to provide more informative error messaging
            BOOL isATTGranted = [CLXAdTrackingService isIDFAAccessAllowed];
            if (!isATTGranted) {
                [logger info:[NSString stringWithFormat:@"📊 [CLXMetaErrorHandler] %@ No Fill (1001) - No ads available for placement %@ | ATT Status: NOT GRANTED | This is likely because App Tracking Transparency permission was not granted. Meta requires ATT for personalized ads. | Recommendation: Consider requesting ATT permission or use other ad networks that support non-personalized ads.", context, placementID]];
                enhancedUserInfo[@"CLXMetaRecommendation"] = @"ATT not granted - Meta requires ATT for ads. Request ATT permission or use other networks.";
                enhancedUserInfo[@"CLXMetaATTStatus"] = @"denied";
                enhancedUserInfo[@"CLXMetaATTRequired"] = @YES;
            } else {
                [logger info:[NSString stringWithFormat:@"📊 [CLXMetaErrorHandler] %@ No Fill (1001) - No ads available for placement %@ | ATT Status: GRANTED | Recommendation: Do not retry immediately. Consider waterfall to next adapter.", context, placementID]];
                enhancedUserInfo[@"CLXMetaRecommendation"] = @"No immediate retry - use waterfall";
                enhancedUserInfo[@"CLXMetaATTStatus"] = @"granted";
            }
            break;
        }
            
        case CLXMetaErrorCodeAdLoadTooFrequently:
            enhancedUserInfo[@"FacebookRateLimited"] = @YES;
            enhancedUserInfo[@"SuggestedMinimumDelay"] = @([self suggestedDelayForError:error]);
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Wait 5+ seconds before retry";
            break;
            
        case CLXMetaErrorCodeNetworkError:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Check network and retry";
            break;
            
        case CLXMetaErrorCodeDisplayFormatMismatch:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Check placement format configuration";
            break;
            
        case CLXMetaErrorCodeUnsupportedSDKVersion:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Update Meta SDK version";
            break;
            
        case CLXMetaErrorCodeNotAppAdminDeveloperOrTester:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Add user as tester in Facebook App";
            break;
            
        case CLXMetaErrorCodeServerError:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Retry after delay";
            break;
            
        case CLXMetaErrorCodeInternalError:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"File bug report if persistent";
            break;
            
        case CLXMetaErrorCodeInvalidPlacement:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Verify placement ID configuration";
            break;
            
        case CLXMetaErrorCodeBidTokenNotFound:
        case CLXMetaErrorCodeInvalidBidToken:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Regenerate bid token";
            break;
            
        case CLXMetaErrorCodeAdExpired:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Load new ad";
            break;
            
        case CLXMetaErrorCodeATTNotDetermined:
        case CLXMetaErrorCodeATTRestricted:
        case CLXMetaErrorCodeATTDenied:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Handle ATT permission";
            break;
            
        default:
            enhancedUserInfo[@"CLXMetaRecommendation"] = @"Check Meta documentation";
            break;
    }
    
    // Add retry and delay metadata (no separate log needed - already in main error log)
    BOOL isRetryable = [self isRetryableError:error];
    NSTimeInterval suggestedDelay = [self suggestedDelayForError:error];
    
    // Get user-friendly message for the error
    NSDictionary *alertInfo = [self userFriendlyAlertInfoForError:error context:context];
    NSString *userFriendlyMessage = alertInfo[@"message"];
    
    // Set the enhanced user-friendly message as the localizedDescription
    if (userFriendlyMessage) {
        enhancedUserInfo[NSLocalizedDescriptionKey] = userFriendlyMessage;
    }
    
    // Create enhanced error with better localizedDescription
    NSError *enhancedError = [NSError errorWithDomain:error.domain
                                                 code:error.code
                                             userInfo:[enhancedUserInfo copy]];
    
    return enhancedError;
}

+ (NSTimeInterval)suggestedDelayForError:(NSError *)error {
    switch (error.code) {
        case CLXMetaErrorCodeAdLoadTooFrequently:
            return 5.0; // Facebook recommends at least 5 seconds
            
        case CLXMetaErrorCodeNetworkError:
        case CLXMetaErrorCodeServerError:
            return 2.0; // Short delay for network/server issues
            
        case CLXMetaErrorCodeInternalError:
            return 1.0; // Brief delay for internal errors
            
        default:
            return 0.0; // No delay needed
    }
}

+ (BOOL)isRetryableError:(NSError *)error {
    switch (error.code) {
        // Retryable errors - temporary issues that might resolve
        case CLXMetaErrorCodeNetworkError:
        case CLXMetaErrorCodeServerError:
        case CLXMetaErrorCodeInternalError:
        case CLXMetaErrorCodeAdLoadTooFrequently:
            return YES;
            
        // Non-retryable errors - configuration or permanent issues
        case CLXMetaErrorCodeNoFill:
        case CLXMetaErrorCodeDisplayFormatMismatch:
        case CLXMetaErrorCodeUnsupportedSDKVersion:
        case CLXMetaErrorCodeNotAppAdminDeveloperOrTester:
        case CLXMetaErrorCodeInvalidPlacement:
        case CLXMetaErrorCodeInvalidBidToken:
        case CLXMetaErrorCodeBidTokenNotFound:
        case CLXMetaErrorCodeAdExpired:
        case CLXMetaErrorCodeATTDenied:
        case CLXMetaErrorCodeATTRestricted:
            return NO;
            
        default:
            return NO; // Conservative approach for unknown errors
    }
}

+ (NSString *)descriptionForErrorCode:(NSInteger)errorCode {
    switch (errorCode) {
        case CLXMetaErrorCodeNetworkError:
            return @"Network Error - Cannot reach Facebook servers";
            
        case CLXMetaErrorCodeNoFill:
            return @"No Fill - No ads available to serve (may be due to ATT permission not granted)";
            
        case CLXMetaErrorCodeAdLoadTooFrequently:
            return @"Ad Load Too Frequently - Rate limited by Facebook SDK";
            
        case CLXMetaErrorCodeInvalidPlacement:
            return @"Invalid Placement - Placement ID not found or invalid";
            
        case CLXMetaErrorCodeAdAlreadyLoaded:
            return @"Ad Already Loaded - Cannot load ad that's already loaded";
            
        case CLXMetaErrorCodeAdNotLoaded:
            return @"Ad Not Loaded - Cannot show ad that hasn't been loaded";
            
        case CLXMetaErrorCodeMediationError:
            return @"Mediation Error - Error in mediation layer";
            
        case CLXMetaErrorCodeBidTokenNotFound:
            return @"Bid Token Not Found - Required bid token is missing";
            
        case CLXMetaErrorCodeInvalidBidToken:
            return @"Invalid Bid Token - Bid token is malformed or expired";
            
        case CLXMetaErrorCodeAdExpired:
            return @"Ad Expired - Ad content has expired and cannot be shown";
            
        case CLXMetaErrorCodeDisplayFormatMismatch:
            return @"Display Format Mismatch - Ad format doesn't match placement";
            
        case CLXMetaErrorCodeUnsupportedSDKVersion:
            return @"Unsupported SDK Version - SDK version no longer supported";
            
        case CLXMetaErrorCodeVideoPlaybackError:
            return @"Video Playback Error - Error playing video ad content";
            
        case CLXMetaErrorCodeVideoNotAvailable:
            return @"Video Not Available - Video content not available";
            
        case CLXMetaErrorCodeNativeAdNotRegistered:
            return @"Native Ad Not Registered - Native ad view not properly registered";
            
        case CLXMetaErrorCodeNativeAdViewNotFound:
            return @"Native Ad View Not Found - Required native ad view missing";
            
        case CLXMetaErrorCodeRewardedVideoNotReady:
            return @"Rewarded Video Not Ready - Rewarded video not ready to show";
            
        case CLXMetaErrorCodeRewardedVideoAlreadyShown:
            return @"Rewarded Video Already Shown - Cannot show rewarded video twice";
            
        case CLXMetaErrorCodePrivacyConsentRequired:
            return @"Privacy Consent Required - User privacy consent needed";
            
        case CLXMetaErrorCodeGDPRConsentRequired:
            return @"GDPR Consent Required - GDPR consent required for EU users";
            
        case CLXMetaErrorCodeATTNotDetermined:
            return @"ATT Not Determined - App Tracking Transparency status not determined";
            
        case CLXMetaErrorCodeATTRestricted:
            return @"ATT Restricted - App Tracking Transparency restricted";
            
        case CLXMetaErrorCodeATTDenied:
            return @"ATT Denied - App Tracking Transparency denied by user";
            
        case CLXMetaErrorCodeNotAppAdminDeveloperOrTester:
            return @"Not App Admin/Developer/Tester - User not authorized for test ads";
            
        case CLXMetaErrorCodeServerError:
            return @"Server Error - Facebook server processing error";
            
        case CLXMetaErrorCodeInternalError:
            return @"Internal Error - Facebook SDK internal error";
            
        default:
            return [NSString stringWithFormat:@"Unknown Error Code %ld - Check Meta documentation", (long)errorCode];
    }
}

+ (NSDictionary *)userFriendlyAlertInfoForError:(NSError *)error context:(NSString *)context {
    if (!error) {
        return @{
            @"title": [NSString stringWithFormat:@"%@ Error", context ?: @"Ad"],
            @"message": @"An unknown error occurred. Please try again."
        };
    }
    
    // Check if this is a Meta FAN SDK error (Facebook domain) or CloudX system error
    BOOL isMetaError = [error.domain containsString:@"facebook"] || 
                       [error.domain containsString:@"FBAudienceNetwork"] ||
                       [error.domain containsString:@"Meta"] ||
                       (error.code >= 1000 && error.code <= 2999); // Meta error code range
    
    NSString *title;
    NSString *message;
    NSInteger errorCode = error.code;
    
    if (isMetaError) {
        // Meta FAN SDK Error - Show detailed Meta-specific information
        title = [NSString stringWithFormat:@"Meta %@ Error", context ?: @"Ad"];
        
        switch (errorCode) {
            case CLXMetaErrorCodeNoFill: {
                // Check ATT status to provide more informative user message
                BOOL isATTGranted = [CLXAdTrackingService isIDFAAccessAllowed];
                if (!isATTGranted) {
                    message = @"No ads are currently available from Meta. This is likely because App Tracking Transparency (ATT) permission has not been granted. Meta requires ATT permission to show personalized ads.\n\nTo resolve this:\n• Grant tracking permission when prompted\n• Or use other ad networks that support non-personalized ads\n\nThis is normal behavior and not an error with your app.";
                } else {
                    message = @"No ads are currently available from Meta. This is normal and will resolve automatically. Please try again in a moment.";
                }
                break;
            }
                
            case CLXMetaErrorCodeAdLoadTooFrequently:
                message = @"Meta has temporarily limited ad requests to prevent spam. Please wait at least 5 seconds before trying again.";
                break;
                
            case CLXMetaErrorCodeNetworkError:
                message = @"Cannot connect to Meta's ad servers. Please check your internet connection and try again.";
                break;
                
            case CLXMetaErrorCodeDisplayFormatMismatch:
                message = @"The ad format doesn't match the placement configuration. This is a setup issue that needs to be resolved in the Meta dashboard.";
                break;
                
            case CLXMetaErrorCodeUnsupportedSDKVersion:
                message = @"The Meta SDK version is no longer supported. The app needs to be updated with a newer SDK version.";
                break;
                
            case CLXMetaErrorCodeNotAppAdminDeveloperOrTester:
                message = @"Test ads are only available to app admins, developers, and testers. Add your Facebook account as a tester in the Meta dashboard.";
                break;
                
            case CLXMetaErrorCodeServerError:
                message = @"Meta's ad servers are experiencing issues. This is temporary and should resolve automatically. Please try again in a moment.";
                break;
                
            case CLXMetaErrorCodeInternalError:
                message = @"Meta's SDK encountered an internal error. If this persists, please contact support.";
                break;
                
            case CLXMetaErrorCodeInvalidPlacement:
                message = @"The placement ID is not recognized by Meta. Please verify the placement configuration in the Meta dashboard.";
                break;
                
            case CLXMetaErrorCodeBidTokenNotFound:
            case CLXMetaErrorCodeInvalidBidToken:
                message = @"The bid token is invalid or missing. This is typically a temporary issue that will resolve automatically.";
                break;
                
            case CLXMetaErrorCodeAdExpired:
                message = @"The ad content has expired and cannot be displayed. A new ad will be loaded automatically.";
                break;
                
            case CLXMetaErrorCodeATTNotDetermined:
            case CLXMetaErrorCodeATTRestricted:
            case CLXMetaErrorCodeATTDenied:
                message = @"App Tracking Transparency permission is required for personalized ads. You can still see non-personalized ads.";
                break;
                
            default:
                message = [NSString stringWithFormat:@"Meta error %ld: %@\n\nThis is a Meta Audience Network issue. Please try again or contact support if it persists.", 
                          (long)errorCode, error.localizedDescription ?: @"Unknown Meta error"];
                break;
        }
        
        // Add technical details for debugging
        NSString *technicalInfo = [NSString stringWithFormat:@"\n\nTechnical Details:\nMeta Error Code: %ld\nDomain: %@", 
                                  (long)errorCode, error.domain ?: @"Unknown"];
        message = [message stringByAppendingString:technicalInfo];
        
    } else {
        // CloudX System Error - Show CloudX-specific information
        title = [NSString stringWithFormat:@"CloudX %@ Error", context ?: @"Ad"];
        
        // Check for specific CloudX error patterns
        NSString *errorDescription = error.localizedDescription ?: @"";
        
        if ([errorDescription containsString:@"queue"] || [errorDescription containsString:@"Queue"]) {
            message = @"No ads are currently available in the CloudX queue. New ads are being loaded automatically. Please wait a moment and try again.";
        } else if ([errorDescription containsString:@"network"] || [errorDescription containsString:@"Network"]) {
            message = @"CloudX cannot connect to the ad servers. Please check your internet connection and try again.";
        } else if ([errorDescription containsString:@"initialization"] || [errorDescription containsString:@"init"]) {
            message = @"CloudX SDK is not properly initialized. Please wait for initialization to complete and try again.";
        } else if ([errorDescription containsString:@"configuration"] || [errorDescription containsString:@"config"]) {
            message = @"CloudX configuration error. Please verify your app key and placement settings.";
        } else if ([errorDescription containsString:@"timeout"] || [errorDescription containsString:@"Timeout"]) {
            message = @"CloudX request timed out. This is usually temporary. Please try again.";
        } else {
            message = [NSString stringWithFormat:@"CloudX system error: %@\n\nThis is an issue with the CloudX SDK or configuration.", errorDescription];
        }
        
        // Add technical details for debugging
        NSString *technicalInfo = [NSString stringWithFormat:@"\n\nTechnical Details:\nCloudX Error Code: %ld\nDomain: %@", 
                                  (long)errorCode, error.domain ?: @"Unknown"];
        message = [message stringByAppendingString:technicalInfo];
    }
    
    return @{
        @"title": title,
        @"message": message
    };
}

+ (NSString *)currentATTStatusDescription {
    if (@available(iOS 14, *)) {
        ATTrackingManagerAuthorizationStatus status = ATTrackingManager.trackingAuthorizationStatus;
        switch (status) {
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                return @"ATT Status: Not Determined (user not yet asked)";
            case ATTrackingManagerAuthorizationStatusRestricted:
                return @"ATT Status: Restricted (parental controls or device management)";
            case ATTrackingManagerAuthorizationStatusDenied:
                return @"ATT Status: Denied (user explicitly denied permission)";
            case ATTrackingManagerAuthorizationStatusAuthorized:
                return @"ATT Status: Authorized (tracking permission granted)";
            default:
                return @"ATT Status: Unknown";
        }
    } else {
        // For iOS 13 and below, check the deprecated API
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        BOOL trackingEnabled = [ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled;
        #pragma clang diagnostic pop
        return trackingEnabled ? @"Pre-iOS 14: Advertising Tracking Enabled" : @"Pre-iOS 14: Advertising Tracking Disabled";
    }
}

@end
