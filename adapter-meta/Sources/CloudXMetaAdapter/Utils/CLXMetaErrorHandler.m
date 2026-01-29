//
//  CLXMetaErrorHandler.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "CLXMetaErrorHandler.h"
#endif

#import <CloudXCore/CLXError.h>

// Meta FAN SDK Error Codes (from official documentation)
// https://developers.facebook.com/docs/audience-network/testing#errors
typedef NS_ENUM(NSInteger, FBAdErrorCode) {
    FBAdErrorCodeNetworkError = 1000,
    FBAdErrorCodeNoFill = 1001,
    FBAdErrorCodeAdLoadTooFrequently = 1002,
    FBAdErrorCodeDisplayFormatMismatch = 1011,
    FBAdErrorCodeUnsupportedSDKVersion = 1012,
    FBAdErrorCodeNotAdminDeveloperOrTester = 1203,
    FBAdErrorCodeServerError = 2000,
    FBAdErrorCodeInternalError = 2001
};

@implementation CLXMetaErrorHandler

+ (CLXError *)toCloudXError:(NSError *)metaError {
    if (!metaError) {
        return [CLXError errorWithCode:CLXErrorCodeAdapterInternalError];
    }

    CLXErrorCode errorCode;

    switch (metaError.code) {
        case FBAdErrorCodeNetworkError:
            errorCode = CLXErrorCodeAdapterNoConnection;
            break;

        case FBAdErrorCodeNoFill:
            errorCode = CLXErrorCodeAdapterNoFill;
            break;

        case FBAdErrorCodeAdLoadTooFrequently:
        case FBAdErrorCodeNotAdminDeveloperOrTester:
            errorCode = CLXErrorCodeAdapterInvalidLoadState;
            break;

        case FBAdErrorCodeDisplayFormatMismatch:
        case FBAdErrorCodeUnsupportedSDKVersion:
            errorCode = CLXErrorCodeAdapterInvalidConfiguration;
            break;

        case FBAdErrorCodeServerError:
            errorCode = CLXErrorCodeAdapterServerError;
            break;

        case FBAdErrorCodeInternalError:
            errorCode = CLXErrorCodeAdapterTimeout;
            break;

        default:
            errorCode = CLXErrorCodeAdapterInternalError;
            break;
    }

    // Create description that includes Meta error details
    NSString *description = [NSString stringWithFormat:@"Meta error %ld: %@",
                             (long)metaError.code,
                             metaError.localizedDescription ?: @"Unknown error"];

    return [CLXError errorWithCode:errorCode
                       description:description
                   underlyingError:metaError];
}

@end
