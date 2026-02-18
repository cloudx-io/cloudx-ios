//
//  CLXInMobiErrorHandler.m
//  CloudXInMobiAdapter
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "CLXInMobiErrorHandler.h"
#endif

#import <CloudXCore/CLXError.h>
#import <InMobiSDK/InMobiSDK.h>

@implementation CLXInMobiErrorHandler

+ (CLXError *)toCloudXError:(NSError *)inMobiError {
    if (!inMobiError) {
        return [CLXError errorWithCode:CLXErrorCodeAdapterInternalError];
    }

    CLXErrorCode errorCode;

    switch (inMobiError.code) {
        case IMStatusCodeNetworkUnReachable:
            errorCode = CLXErrorCodeAdapterNoConnection;
            break;
        case IMStatusCodeNoFill:
            errorCode = CLXErrorCodeAdapterNoFill;
            break;
        case IMStatusCodeSdkNotInitialised:
            errorCode = CLXErrorCodeAdapterNotInitialized;
            break;
        case IMStatusCodeRequestInvalid:
        case IMStatusCodeInvalidBannerframe:
            errorCode = CLXErrorCodeAdapterBadRequest;
            break;
        case IMStatusCodeIncorrectPlacementID:
            errorCode = CLXErrorCodeAdapterInvalidConfiguration;
            break;
        case IMStatusCodeRequestPending:
        case IMStatusCodeMultipleLoadsOnSameInstance:
        case IMStatusCodeAdActive:
        case IMStatusCodeEarlyRefreshRequest:
            errorCode = CLXErrorCodeAdapterInvalidLoadState;
            break;
        case IMStatusCodeRequestTimedOut:
            errorCode = CLXErrorCodeAdapterTimeout;
            break;
        case IMStatusCodeInternalError:
        case IMStatusCodeDroppingNetworkRequest:
        case IMStatusCodeInvalidAudioFrame:
        case IMStatusCodeAudioDisabled:
        case IMStatusCodeAudioDeviceVolumeLow:
            errorCode = CLXErrorCodeAdapterInternalError;
            break;
        case IMStatusCodeServerError:
            errorCode = CLXErrorCodeAdapterServerError;
            break;
        default:
            errorCode = CLXErrorCodeAdapterInternalError;
            break;
    }

    NSString *description = [NSString stringWithFormat:@"InMobi error %ld: %@",
                             (long)inMobiError.code,
                             inMobiError.localizedDescription ?: @"Unknown error"];

    return [CLXError errorWithCode:errorCode
                       description:description
                   underlyingError:inMobiError];
}

@end
