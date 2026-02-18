//
//  CLXVungleErrorHandler.m
//  CloudXVungleAdapter
//

#import "CLXVungleErrorHandler.h"
#import <CloudXCore/CLXError.h>

@implementation CLXVungleErrorHandler

+ (CLXError *)toCloudXError:(NSError *)vungleError isShowError:(BOOL)isShowError {
    if (!vungleError) {
        return [CLXError errorWithCode:CLXErrorCodeAdapterInternalError];
    }

    CLXErrorCode errorCode;

    switch (vungleError.code) {

        // --- Not Initialized ---
        case 6:  // VungleErrorSdkNotInitialized
            errorCode = CLXErrorCodeAdapterNotInitialized;
            break;

        // --- Invalid Configuration ---
        case 2:    // VungleErrorInvalidAppID
        case 201:  // VungleErrorInvalidPlacementID
        case 207:  // VungleErrorPlacementAdTypeMismatch
        case 222:  // VungleErrorInvalidWaterfallPlacementID
        case 500:  // VungleErrorBannerViewInvalidSize
        case 30001: // VungleErrorAdPublisherMismatch
            errorCode = CLXErrorCodeAdapterInvalidConfiguration;
            break;

        // --- Missing View Controller ---
        case 2009: // VungleErrorInvalidPlayParameter
            errorCode = CLXErrorCodeAdapterMissingViewController;
            break;

        // --- Internal Error ---
        case 119:   // VungleErrorJsonEncodeError
        case 30002: // VungleErrorAdInternalIntegrationError
        case 30003: // VungleErrorConfigNotFoundError
        case 106:   // VungleErrorInvalidRequestBuilderError
        case 131:   // VungleErrorMraidJsWriteFailed
        case 130:   // VungleErrorMraidDownloadJsError
        case 218:   // VungleErrorMraidJsDoesNotExist
        case 219:   // VungleErrorMraidJsCopyFailed
        case 109:   // VungleErrorTemplateUnzipError
        case 114:   // VungleErrorAssetWriteError
            errorCode = CLXErrorCodeAdapterInternalError;
            break;

        // --- Invalid Load State ---
        case 202:  // VungleErrorAdConsumed
        case 203:  // VungleErrorAdIsLoading
        case 204:  // VungleErrorAdAlreadyLoaded
        case 205:  // VungleErrorAdIsPlaying
        case 206:  // VungleErrorAdAlreadyFailed
        case 214:  // VungleErrorInvalidGzipBidPayload
        case 208:  // VungleErrorInvalidBidPayload
        case 209:  // VungleErrorInvalidJsonBidPayload
        case 216:  // VungleErrorInvalidAdunitBidPayload
        case 215:  // VungleErrorAdResponseEmpty
        case 200:  // VungleErrorInvalidEventIDError
        case 101:  // VungleErrorApiRequestError
        case 102:  // VungleErrorApiResponseDataError
        case 103:  // VungleErrorApiResponseDecodeError
        case 104:  // VungleErrorApiFailedStatusCode
        case 105:  // VungleErrorInvalidTemplateURL
        case 111:  // VungleErrorInvalidAssetURL
        case 112:  // VungleErrorAssetRequestError
        case 113:  // VungleErrorAssetResponseDataError
        case 117:  // VungleErrorAssetFailedStatusCode
            errorCode = CLXErrorCodeAdapterInvalidLoadState;
            break;

        // --- Ad Not Loaded (context-dependent) ---
        case 210:  // VungleErrorAdNotLoaded
            errorCode = isShowError ? CLXErrorCodeAdapterAdNotReady : CLXErrorCodeAdapterInvalidLoadState;
            break;

        // --- Display Failed ---
        case 115:  // VungleErrorInvalidIndexURL
        case 302:  // VungleErrorInvalidIfaStatus
        case 305:  // VungleErrorMraidBridgeError
        case 400:  // VungleErrorConcurrentPlaybackUnsupported
        case 317:  // VungleErrorAdClosedTemplateError
        case 318:  // VungleErrorAdClosedMissingHeartbeat
            errorCode = CLXErrorCodeAdapterDisplayFailed;
            break;

        // --- No Fill ---
        case 212:   // VungleErrorPlacementSleep
        case 10001: // VungleErrorAdNoFill
        case 10002: // VungleErrorAdLoadTooFrequently
            errorCode = CLXErrorCodeAdapterNoFill;
            break;

        // --- Timeout ---
        case 217:  // VungleErrorAdResponseTimedOut
            errorCode = CLXErrorCodeAdapterTimeout;
            break;

        // --- Server Error ---
        case 220:   // VungleErrorAdResponseRetryAfter
        case 221:   // VungleErrorAdLoadFailRetryAfter
        case 20001: // VungleErrorAdServerError
            errorCode = CLXErrorCodeAdapterServerError;
            break;

        // --- Ad Expired ---
        case 304:  // VungleErrorAdExpired
        case 307:  // VungleErrorAdExpiredOnPlay
            errorCode = CLXErrorCodeAdapterAdExpired;
            break;

        // --- WebView Error ---
        case 2000: // VungleErrorWebViewWebContentProcessDidTerminate
        case 2001: // VungleErrorWebViewFailedNavigation
        case 320:  // VungleErrorWebviewError
            errorCode = CLXErrorCodeAdapterWebViewError;
            break;

        default:
            errorCode = CLXErrorCodeAdapterInternalError;
            break;
    }

    NSString *description = [NSString stringWithFormat:@"Vungle error %ld: %@",
                             (long)vungleError.code,
                             vungleError.localizedDescription ?: @"Unknown error"];

    return [CLXError errorWithCode:errorCode
                       description:description
                   underlyingError:vungleError];
}

@end
