#import "CLXMintegralErrorHandler.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDK/MTGErrorCodeConstant.h>

// Additional Mintegral error codes not defined in API, but in their docs
// http://cdn-adn.rayjump.com/cdn-adn/v2/markdown_v2/index.html?file=sdk-m_sdk-ios&lang=en#faqs
#define EXCEPTION_RETURN_EMPTY -1                   // ads no fill
#define EXCEPTION_TIMEOUT -9                        // request timeout
#define EXCEPTION_IV_RECALLNET_INVALIDATE -1904     // Network status incorrect at request time
#define EXCEPTION_SIGN_ERROR -10                    // AppID and appKey do not match correctly
#define EXCEPTION_UNIT_NOT_FOUND -1201              // Can not find the unitID in dashboard
#define EXCEPTION_UNIT_ID_EMPTY -1202               // unitID is empty
#define EXCEPTION_UNIT_NOT_FOUND_IN_APP -1203       // Can not find the unitID of the appID
#define EXCEPTION_UNIT_ADTYPE_ERROR -1205           // The adtype of the unitID is wrong
#define EXCEPTION_APP_ID_EMPTY -1301                // appID is empty
#define EXCEPTION_APP_NOT_FOUND -1302               // Can not find the appId

@implementation CLXMintegralErrorHandler

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID {
    
    CLXErrorCode cloudXCode = CLXErrorCodeUnknown;
    NSString *description = networkError.localizedDescription ?: @"Unknown error";
    NSString *recoverySuggestion = nil;
    BOOL shouldRetry = NO;
    
    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: code=%ld, %@",
                   context, placementID ?: @"N/A", (long)networkError.code, description]];
    
    // Map Mintegral-specific errors to CloudX errors
    // Using real MTGErrorCode constants from MTGErrorCodeConstant.h (matching AppLovin)
    NSInteger errorCode = networkError.code;
    
    switch (errorCode) {
        // Configuration errors
        case KMTGErrorCodeEmptyUnitId:
        case EXCEPTION_SIGN_ERROR:
        case EXCEPTION_UNIT_NOT_FOUND:
        case EXCEPTION_UNIT_ID_EMPTY:
        case EXCEPTION_UNIT_NOT_FOUND_IN_APP:
        case EXCEPTION_UNIT_ADTYPE_ERROR:
        case EXCEPTION_APP_ID_EMPTY:
        case EXCEPTION_APP_NOT_FOUND:
        case kMTGErrorCodeBannerSizeInvalid:
            cloudXCode = CLXErrorCodeInvalidConfiguration;
            description = @"Invalid Mintegral configuration (App ID, Unit ID, or placement)";
            recoverySuggestion = @"Verify your Mintegral dashboard configuration";
            shouldRetry = NO;
            break;
            
        // No fill errors
        case kMTGErrorCodeNoAds:
        case kMTGErrorCodeNoAdsAvailableToPlay:
        case EXCEPTION_RETURN_EMPTY:
            cloudXCode = CLXErrorCodeNoFill;
            description = @"No fill for ad request from Mintegral";
            recoverySuggestion = @"Try again later or check placement configuration";
            shouldRetry = YES;
            break;
            
        // Network errors
        case kMTGErrorCodeConnectionLost:
        case kMTGErrorCodeSocketIO:
            cloudXCode = CLXErrorCodeNetworkError;
            description = @"Mintegral network connectivity issue";
            recoverySuggestion = @"Check internet connection and try again";
            shouldRetry = YES;
            break;
            
        // Frequency cap
        case kMTGErrorCodeDailyLimit:
            cloudXCode = CLXErrorCodeRateLimit;
            description = @"Mintegral frequency cap reached";
            recoverySuggestion = @"Wait before requesting more ads";
            shouldRetry = NO;
            break;
            
        // Timeout errors
        case kMTGErrorCodeLoadAdsTimeOut:
        case EXCEPTION_TIMEOUT:
            cloudXCode = CLXErrorCodeTimeout;
            description = @"Mintegral ad request timed out";
            recoverySuggestion = @"Try again";
            shouldRetry = YES;
            break;
            
        // Ad expired
        case kMTGErrorCodeOfferExpired:
            cloudXCode = CLXErrorCodeAdExpired;
            description = @"Mintegral ad offer expired";
            recoverySuggestion = @"Request a new ad";
            shouldRetry = YES;
            break;
            
        // Not initialized
        case EXCEPTION_IV_RECALLNET_INVALIDATE:
            cloudXCode = CLXErrorCodeNotInitialized;
            description = @"Mintegral SDK not initialized or network invalid at request time";
            recoverySuggestion = @"Ensure SDK is initialized before loading ads";
            shouldRetry = NO;
            break;
            
        // Bid token errors
        case KMTGErrorCodeEmptyBidToken:
            cloudXCode = CLXErrorCodeInvalidBidResponse;
            description = @"Empty or invalid bid token for Mintegral";
            recoverySuggestion = @"Request a new bid token";
            shouldRetry = YES;
            break;
            
        // Internal/load/show errors
        case kMTGErrorCodeUnknownError:
        case kMTGErrorCodeRewardVideoFailedToLoadVideoData:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayable:
        case kMTGErrorCodeRewardVideoFailedToLoadTemplateImage:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLFailed:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLReadyTimeOut:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLReadyNO:
        case kMTGErrorCodeRewardVideoFailedToLoadPlayableURLInvalid:
        case kMTGErrorCodeRewardVideoFailedToLoadMd5Invalid:
        case kMTGErrorCodeRewardVideoFailedToSettingInvalid:
        case kMTGErrorCodeURLisEmpty:
        case kMTGErrorCodeFailedToPlay:
        case kMTGErrorCodeFailedToLoad:
        case kMTGErrorCodeFailedToShow:
        case kMTGErrorCodeFailedToShowCbp:
        case kMTGErrorCodeMaterialLoadFailed:
        case kMTGErrorCodeNoSupportPopupWindow:
        case kMTGErrorCodeFailedDiskIO:
        case kMTGErrorCodeImageURLisEmpty:
        case kMTGErrorCodeAdsCountInvalid:
        case kMTGErrorCodeSocketInvalidStatus:
        case kMTGErrorCodeSocketInvalidContent:
            cloudXCode = CLXErrorCodeInternalError;
            description = [NSString stringWithFormat:@"Mintegral internal error: %ld", (long)errorCode];
            recoverySuggestion = @"Try again or contact support if this persists";
            shouldRetry = YES;
            break;
            
        default:
            cloudXCode = CLXErrorCodeUnknown;
            description = [NSString stringWithFormat:@"Unknown Mintegral error: %ld - %@", 
                          (long)errorCode, networkError.localizedDescription];
            recoverySuggestion = @"Check Mintegral SDK documentation for error code";
            shouldRetry = NO;
            break;
    }
    
    return [CLXError errorWithCode:cloudXCode
                       description:description
                recoverySuggestion:recoverySuggestion
                          userInfo:@{
                              NSUnderlyingErrorKey: networkError,
                              @"ShouldRetry": @(shouldRetry),
                              @"MintegralErrorCode": @(errorCode)
                          }];
}

@end

