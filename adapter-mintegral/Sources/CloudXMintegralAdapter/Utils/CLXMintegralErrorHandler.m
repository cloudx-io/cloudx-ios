#import "CLXMintegralErrorHandler.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDK/MTGErrorCodeConstant.h>

// Additional Mintegral error codes from their documentation
// http://cdn-adn.rayjump.com/cdn-adn/v2/markdown_v2/index.html?file=sdk-m_sdk-ios&lang=en#faqs
static const NSInteger kMTGExceptionReturnEmpty = -1;                    // ads no fill
static const NSInteger kMTGExceptionTimeout = -9;                        // request timeout
static const NSInteger kMTGExceptionNetworkInvalidate = -1904;           // Network invalid at request time
static const NSInteger kMTGExceptionSignError = -10;                     // AppID/appKey mismatch
static const NSInteger kMTGExceptionUnitNotFound = -1201;                // unitID not found in dashboard
static const NSInteger kMTGExceptionUnitIdEmpty = -1202;                 // unitID is empty
static const NSInteger kMTGExceptionUnitNotFoundInApp = -1203;           // unitID not found for appID
static const NSInteger kMTGExceptionUnitAdtypeError = -1205;             // Wrong adtype for unitID
static const NSInteger kMTGExceptionAppIdEmpty = -1301;                  // appID is empty
static const NSInteger kMTGExceptionAppNotFound = -1302;                 // appID not found

@implementation CLXMintegralErrorHandler

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID {
    
    CLXErrorCode cloudXCode = CLXErrorCodeInternalError;
    NSString *description = networkError.localizedDescription ?: @"Unknown error";
    BOOL shouldRetry = NO;
    
    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: code=%ld, %@",
                   context, placementID ?: @"N/A", (long)networkError.code, description]];
    
    NSInteger errorCode = networkError.code;
    
    // Configuration errors
    if (errorCode == KMTGErrorCodeEmptyUnitId ||
        errorCode == kMTGExceptionSignError ||
        errorCode == kMTGExceptionUnitNotFound ||
        errorCode == kMTGExceptionUnitIdEmpty ||
        errorCode == kMTGExceptionUnitNotFoundInApp ||
        errorCode == kMTGExceptionUnitAdtypeError ||
        errorCode == kMTGExceptionAppIdEmpty ||
        errorCode == kMTGExceptionAppNotFound ||
        errorCode == kMTGErrorCodeBannerSizeInvalid) {
        cloudXCode = CLXErrorCodeAdapterInvalidConfiguration;
        description = @"Invalid Mintegral configuration (App ID, Unit ID, or placement)";
        shouldRetry = NO;
    }
    // No fill errors
    else if (errorCode == kMTGErrorCodeNoAds ||
             errorCode == kMTGErrorCodeNoAdsAvailableToPlay ||
             errorCode == kMTGExceptionReturnEmpty) {
        cloudXCode = CLXErrorCodeNoFill;
        description = @"No fill for ad request from Mintegral";
        shouldRetry = YES;
    }
    // Network errors
    else if (errorCode == kMTGErrorCodeConnectionLost ||
             errorCode == kMTGErrorCodeSocketIO) {
        cloudXCode = CLXErrorCodeNetworkError;
        description = @"Mintegral network connectivity issue";
        shouldRetry = YES;
    }
    // Frequency cap
    else if (errorCode == kMTGErrorCodeDailyLimit) {
        cloudXCode = CLXErrorCodeTooManyRequests;
        description = @"Mintegral frequency cap reached";
        shouldRetry = NO;
    }
    // Timeout errors
    else if (errorCode == kMTGErrorCodeLoadAdsTimeOut ||
             errorCode == kMTGExceptionTimeout) {
        cloudXCode = CLXErrorCodeAdapterTimeout;
        description = @"Mintegral ad request timed out";
        shouldRetry = YES;
    }
    // Ad expired
    else if (errorCode == kMTGErrorCodeOfferExpired) {
        cloudXCode = CLXErrorCodeAdapterAdExpired;
        description = @"Mintegral ad offer expired";
        shouldRetry = YES;
    }
    // Not initialized / network invalid
    else if (errorCode == kMTGExceptionNetworkInvalidate) {
        cloudXCode = CLXErrorCodeNotInitialized;
        description = @"Mintegral SDK not initialized or network invalid";
        shouldRetry = NO;
    }
    // Bid token errors
    else if (errorCode == KMTGErrorCodeEmptyBidToken) {
        cloudXCode = CLXErrorCodeAdapterInternalError;
        description = @"Empty or invalid bid token for Mintegral";
        shouldRetry = YES;
    }
    // Show failed
    else if (errorCode == kMTGErrorCodeFailedToShow ||
             errorCode == kMTGErrorCodeFailedToShowCbp ||
             errorCode == kMTGErrorCodeFailedToPlay) {
        cloudXCode = CLXErrorCodeShowFailed;
        description = @"Mintegral ad show failed";
        shouldRetry = NO;
    }
    // Load failed (video/material/internal)
    else if (errorCode == kMTGErrorCodeFailedToLoad ||
             errorCode == kMTGErrorCodeMaterialLoadFailed ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadVideoData ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadPlayable ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadTemplateImage ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadPlayableURLFailed ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadPlayableURLReadyTimeOut ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadPlayableURLReadyNO ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadPlayableURLInvalid ||
             errorCode == kMTGErrorCodeRewardVideoFailedToLoadMd5Invalid ||
             errorCode == kMTGErrorCodeRewardVideoFailedToSettingInvalid) {
        cloudXCode = CLXErrorCodeLoadFailed;
        description = @"Mintegral ad load failed";
        shouldRetry = YES;
    }
    // Internal/unknown errors
    else if (errorCode == kMTGErrorCodeUnknownError ||
             errorCode == kMTGErrorCodeURLisEmpty ||
             errorCode == kMTGErrorCodeImageURLisEmpty ||
             errorCode == kMTGErrorCodeAdsCountInvalid ||
             errorCode == kMTGErrorCodeNoSupportPopupWindow ||
             errorCode == kMTGErrorCodeFailedDiskIO ||
             errorCode == kMTGErrorCodeSocketInvalidStatus ||
             errorCode == kMTGErrorCodeSocketInvalidContent) {
        cloudXCode = CLXErrorCodeInternalError;
        description = [NSString stringWithFormat:@"Mintegral internal error: %ld", (long)errorCode];
        shouldRetry = NO;
    }
    // Default
    else {
        cloudXCode = CLXErrorCodeInternalError;
        description = [NSString stringWithFormat:@"Unknown Mintegral error: %ld - %@", 
                      (long)errorCode, networkError.localizedDescription];
        shouldRetry = NO;
    }
    
    // Build user info with underlying error
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    userInfo[NSUnderlyingErrorKey] = networkError;
    userInfo[@"ShouldRetry"] = @(shouldRetry);
    userInfo[@"MintegralErrorCode"] = @(errorCode);
    
    return [CLXError errorWithCode:cloudXCode userInfo:userInfo];
}

@end
