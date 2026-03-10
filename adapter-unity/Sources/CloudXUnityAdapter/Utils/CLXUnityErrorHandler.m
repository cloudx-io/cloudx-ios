//
//  CLXUnityErrorHandler.m
//  CloudXUnityAdapter
//

#if __has_include(<CloudXUnityAdapter/CLXUnityErrorHandler.h>)
#import <CloudXUnityAdapter/CLXUnityErrorHandler.h>
#else
#import "CLXUnityErrorHandler.h"
#endif

#import <CloudXCore/CLXError.h>

@implementation CLXUnityErrorHandler

+ (CLXError *)toCloudXError:(id<UnityAdsError>)error {
    if (!error) {
        return [CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                           description:@"Unity unknown error"];
    }

    // Unity 4.17.0 uses protobuf-based error codes from PublicErrorCode enum.
    // Codes verified on Android via bytecode + live device testing.
    CLXErrorCode errorCode;
    NSInteger code = error.code;

    switch (code) {
        // General
        case 2: errorCode = CLXErrorCodeAdapterTimeout; break;                  // TIMEOUT

        // Init errors (52000-52006)
        case 52000: errorCode = CLXErrorCodeAdapterInitializationError; break;  // INIT_UNKNOWN
        case 52001: errorCode = CLXErrorCodeAdapterInvalidConfiguration; break; // INIT_NOT_FOUND
        case 52002: errorCode = CLXErrorCodeAdapterInvalidConfiguration; break; // INIT_MISMATCHED_PLATFORM
        case 52003: errorCode = CLXErrorCodeAdapterInternalError; break;        // INIT_PROTO
        case 52004: errorCode = CLXErrorCodeAdapterInternalError; break;        // INIT_INTERNAL_SYSTEM
        case 52005: errorCode = CLXErrorCodeAdapterNoConnection; break;         // INIT_NETWORK
        case 52006: errorCode = CLXErrorCodeAdapterInternalError; break;        // INIT_FILE_SYSTEM

        // Load errors (52100-52107)
        case 52100: errorCode = CLXErrorCodeAdapterNoFill; break;               // LOAD_NO_FILL
        case 52101: errorCode = CLXErrorCodeAdapterNotInitialized; break;       // LOAD_NOT_INITIALIZED
        case 52102: errorCode = CLXErrorCodeAdapterInvalidConfiguration; break; // LOAD_PLACEMENT_NOT_FOUND
        case 52103: errorCode = CLXErrorCodeAdapterInternalError; break;        // LOAD_PROTO
        case 52104: errorCode = CLXErrorCodeAdapterInvalidConfiguration; break; // LOAD_UNSUPPORTED_PLACEMENT
        case 52105: errorCode = CLXErrorCodeAdapterNoConnection; break;         // LOAD_NETWORK
        case 52106: errorCode = CLXErrorCodeAdapterInternalError; break;        // LOAD_FILE_SYSTEM
        case 52107: errorCode = CLXErrorCodeAdapterDisplayFailed; break;        // LOAD_ADVIEWER

        // Show errors (52200-52202)
        case 52200: errorCode = CLXErrorCodeAdapterAdExpired; break;            // SHOW_EXPIRED
        case 52201: errorCode = CLXErrorCodeAdapterInvalidLoadState; break;     // SHOW_ALREADY_SHOWN
        case 52202: errorCode = CLXErrorCodeAdapterInternalError; break;        // SHOW_INTERNAL

        default: errorCode = CLXErrorCodeAdapterInternalError; break;
    }

    NSString *description = [NSString stringWithFormat:@"[Unity] error %ld: %@",
                             (long)code, error.message ?: @"Unknown"];
    return [CLXError errorWithCode:errorCode description:description];
}

@end
