#import "CLXMintegralErrorHandler.h"
#import <CloudXCore/CLXError.h>
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

+ (CLXError *)toCloudXError:(NSError *)mintegralError {
    if (!mintegralError) {
        return [CLXError errorWithCode:CLXErrorCodeAdapterInternalError];
    }

    CLXErrorCode cloudXCode = CLXErrorCodeInternalError;
    NSInteger errorCode = mintegralError.code;

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
    }
    // No fill errors
    else if (errorCode == kMTGErrorCodeNoAds ||
             errorCode == kMTGErrorCodeNoAdsAvailableToPlay ||
             errorCode == kMTGExceptionReturnEmpty) {
        cloudXCode = CLXErrorCodeNoFill;
    }
    // Network errors
    else if (errorCode == kMTGErrorCodeConnectionLost ||
             errorCode == kMTGErrorCodeSocketIO) {
        cloudXCode = CLXErrorCodeNetworkError;
    }
    // Frequency cap
    else if (errorCode == kMTGErrorCodeDailyLimit) {
        cloudXCode = CLXErrorCodeTooManyRequests;
    }
    // Timeout errors
    else if (errorCode == kMTGErrorCodeLoadAdsTimeOut ||
             errorCode == kMTGExceptionTimeout) {
        cloudXCode = CLXErrorCodeAdapterTimeout;
    }
    // Ad expired
    else if (errorCode == kMTGErrorCodeOfferExpired) {
        cloudXCode = CLXErrorCodeAdapterAdExpired;
    }
    // Not initialized / network invalid
    else if (errorCode == kMTGExceptionNetworkInvalidate) {
        cloudXCode = CLXErrorCodeNotInitialized;
    }
    // Bid token errors
    else if (errorCode == KMTGErrorCodeEmptyBidToken) {
        cloudXCode = CLXErrorCodeAdapterInternalError;
    }
    // Show failed
    else if (errorCode == kMTGErrorCodeFailedToShow ||
             errorCode == kMTGErrorCodeFailedToShowCbp ||
             errorCode == kMTGErrorCodeFailedToPlay) {
        cloudXCode = CLXErrorCodeAdapterDisplayFailed;
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
    }

    // Create description that includes Mintegral error details
    NSString *description = [NSString stringWithFormat:@"Mintegral error %ld: %@",
                             (long)mintegralError.code,
                             mintegralError.localizedDescription ?: @"Unknown error"];

    return [CLXError errorWithCode:cloudXCode
                       description:description
                   underlyingError:mintegralError];
}

@end
