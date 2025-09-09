//
// CLXError.m
// CloudXCore
//
// Industry-standard error handling implementation
//

#import <CloudXCore/CLXError.h>

NSString * const CLXErrorDomain = @"CLXErrorDomain";

@implementation CLXError

+ (instancetype)errorWithCode:(CLXErrorCode)code {
    return [self errorWithCode:code userInfo:nil];
}

+ (instancetype)errorWithCode:(CLXErrorCode)code description:(NSString *)description {
    NSDictionary *userInfo = description ? @{NSLocalizedDescriptionKey: description} : nil;
    return [self errorWithCode:code userInfo:userInfo];
}

+ (instancetype)errorWithCode:(CLXErrorCode)code userInfo:(nullable NSDictionary *)userInfo {
    NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
    
    // Add localized description based on error code if not provided
    if (!userInfo[NSLocalizedDescriptionKey]) {
        NSString *localizedDescription = [CLXError localizedDescriptionForCode:code];
        if (localizedDescription) {
            errorUserInfo[NSLocalizedDescriptionKey] = localizedDescription;
        }
    }
    
    // Add any additional user info
    if (userInfo) {
        [errorUserInfo addEntriesFromDictionary:userInfo];
    }
    
    return [[self alloc] initWithDomain:CLXErrorDomain code:code userInfo:errorUserInfo];
}

- (instancetype)initWithCode:(CLXErrorCode)code {
    return [self initWithCode:code userInfo:nil];
}

- (instancetype)initWithCode:(CLXErrorCode)code userInfo:(nullable NSDictionary *)userInfo {
    NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
    
    // Add localized description based on error code if not provided
    if (!userInfo[NSLocalizedDescriptionKey]) {
        NSString *localizedDescription = [CLXError localizedDescriptionForCode:code];
        if (localizedDescription) {
            errorUserInfo[NSLocalizedDescriptionKey] = localizedDescription;
        }
    }
    
    // Add any additional user info
    if (userInfo) {
        [errorUserInfo addEntriesFromDictionary:userInfo];
    }
    
    return [self initWithDomain:CLXErrorDomain code:code userInfo:errorUserInfo];
}

+ (NSString *)localizedDescriptionForCode:(CLXErrorCode)code {
    switch (code) {
        // INITIALIZATION ERRORS (100-199)
        case CLXErrorCodeNotInitialized:
            return @"SDK not initialized. Please initialize the SDK before using it.";
        case CLXErrorCodeInitializationInProgress:
            return @"SDK initialization is already in progress.";
        case CLXErrorCodeNoAdaptersFound:
            return @"No ad network adapters found. Please ensure adapters are properly integrated.";
        case CLXErrorCodeInitializationTimeout:
            return @"SDK initialization timed out.";
        case CLXErrorCodeInvalidAppKey:
            return @"Invalid app key provided. Please check your app key.";
        case CLXErrorCodeSDKDisabled:
            return @"SDK has been disabled by kill switch.";
            
        // NETWORK ERRORS (200-299)
        case CLXErrorCodeNetworkError:
            return @"Network error occurred. Please check your internet connection.";
        case CLXErrorCodeNetworkTimeout:
            return @"Network request timed out.";
        case CLXErrorCodeInvalidResponse:
            return @"Invalid response received from server.";
        case CLXErrorCodeServerError:
            return @"Server error occurred.";
            
        // AD REQUEST/LOADING ERRORS (300-399)
        case CLXErrorCodeNoFill:
            return @"No ad available to show.";
        case CLXErrorCodeInvalidRequest:
            return @"Invalid ad request parameters.";
        case CLXErrorCodeInvalidPlacement:
            return @"Invalid placement ID. Please check your placement configuration.";
        case CLXErrorCodeLoadTimeout:
            return @"Ad loading timed out.";
        case CLXErrorCodeLoadFailed:
            return @"Failed to load ad.";
        case CLXErrorCodeInvalidAd:
            return @"Ad content is invalid or corrupted.";
        case CLXErrorCodeTooManyRequests:
            return @"Too many ad requests. Please reduce request frequency.";
        case CLXErrorCodeRequestCancelled:
            return @"Ad request was cancelled.";
        case CLXErrorCodeAdsDisabled:
            return @"Ads have been disabled by kill switch.";
            
        // AD DISPLAY/SHOW ERRORS (400-499)
        case CLXErrorCodeAdNotReady:
            return @"Ad is not ready to be displayed.";
        case CLXErrorCodeAdAlreadyShown:
            return @"Ad has already been shown.";
        case CLXErrorCodeAdExpired:
            return @"Ad has expired and cannot be shown.";
        case CLXErrorCodeInvalidViewController:
            return @"Invalid view controller provided for ad display.";
        case CLXErrorCodeShowFailed:
            return @"Failed to show ad.";
            
        // CONFIGURATION/SETUP ERRORS (500-599)
        case CLXErrorCodeInvalidAdUnit:
            return @"Invalid ad unit configuration.";
        case CLXErrorCodePermissionDenied:
            return @"Required permissions not granted.";
        case CLXErrorCodeUnsupportedAdFormat:
            return @"Ad format not supported.";
        case CLXErrorCodeInvalidBannerView:
            return @"Banner view is nil or invalid.";
        case CLXErrorCodeInvalidNativeView:
            return @"Native view is nil or invalid.";
            
        // LEGACY ERROR CODES (backwards compatibility)
        case CLXErrorCodeGeneralAdError:
            return @"General ad error occurred.";
        case CLXErrorCodeBannerViewError:
            return @"Banner view error occurred.";
        case CLXErrorCodeNativeViewError:
            return @"Native view error occurred.";
        case CLXErrorCodeNoAdsLoaded:
            return @"No ads were loaded.";
        case CLXErrorCodeFailToInitSDK:
            return @"Failed to initialize SDK.";
        case CLXErrorCodeSDKInitialisationInProgress:
            return @"SDK initialization is already in progress.";
        case CLXErrorCodeSDKInitializedWithoutAdapters:
            return @"SDK initialized but no adapters were found.";
        case CLXErrorCodeNoBidTokenSource:
            return @"No bid token source available.";
            
        default:
            return @"Unknown error occurred.";
    }
}

@end
