//
// CLXError.m
// CloudXCore
//
// Industry-standard error codes following AppLovin MAX, Google Mobile Ads, and Unity Ads patterns
//

#import "CLXError.h"

NSString * const CLXErrorDomain = @"com.cloudx.sdk.error";

@implementation CLXError

#pragma mark - Factory Methods

+ (instancetype)errorWithCode:(CLXErrorCode)code {
    return [self errorWithCode:code description:[self defaultDescriptionForCode:code]];
}

+ (instancetype)errorWithCode:(CLXErrorCode)code description:(NSString *)description {
    return [self errorWithCode:code userInfo:@{NSLocalizedDescriptionKey: description}];
}

+ (instancetype)errorWithHTTPStatusCode:(NSInteger)httpStatusCode {
    CLXErrorCode code;
    NSString *description;
    
    switch (httpStatusCode) {
        case 400:
            code = CLXErrorCodeInvalidRequest;
            description = @"Bad Request - Invalid request parameters";
            break;
        case 401:
            code = CLXErrorCodeInvalidAppKey;
            description = @"Unauthorized - Invalid app key";
            break;
        case 403:
            code = CLXErrorCodePermissionDenied;
            description = @"Forbidden - Permission denied";
            break;
        case 404:
            code = CLXErrorCodeNoFill;
            description = @"Not Found - No ad fill available";
            break;
        case 408:
            code = CLXErrorCodeNetworkTimeout;
            description = @"Request Timeout";
            break;
        case 429:
            code = CLXErrorCodeTooManyRequests;
            description = @"Too Many Requests - Rate limited";
            break;
        case 500:
        case 502:
        case 503:
        case 504:
            code = CLXErrorCodeServerError;
            description = [NSString stringWithFormat:@"Server Error - HTTP %ld", (long)httpStatusCode];
            break;
        default:
            if (httpStatusCode >= 400 && httpStatusCode < 500) {
                code = CLXErrorCodeInvalidRequest;
                description = [NSString stringWithFormat:@"Client Error - HTTP %ld", (long)httpStatusCode];
            } else if (httpStatusCode >= 500) {
                code = CLXErrorCodeServerError;
                description = [NSString stringWithFormat:@"Server Error - HTTP %ld", (long)httpStatusCode];
            } else {
                code = CLXErrorCodeNetworkError;
                description = [NSString stringWithFormat:@"Network Error - HTTP %ld", (long)httpStatusCode];
            }
            break;
    }
    
    return [self errorWithCode:code description:description];
}

+ (instancetype)errorWithCode:(CLXErrorCode)code userInfo:(NSDictionary *)userInfo {
    return [[self alloc] initWithCode:code userInfo:userInfo];
}

#pragma mark - Initialization

- (instancetype)initWithCode:(CLXErrorCode)code {
    return [self initWithCode:code userInfo:nil];
}

- (instancetype)initWithCode:(CLXErrorCode)code userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *finalUserInfo = [NSMutableDictionary dictionary];
    
    // Add default description if not provided
    if (!userInfo[NSLocalizedDescriptionKey]) {
        finalUserInfo[NSLocalizedDescriptionKey] = [self.class defaultDescriptionForCode:code];
    }
    
    // Add provided user info
    if (userInfo) {
        [finalUserInfo addEntriesFromDictionary:userInfo];
    }
    
    // Add error code to user info for debugging
    finalUserInfo[@"CLXErrorCode"] = @(code);
    
    return [super initWithDomain:CLXErrorDomain code:code userInfo:[finalUserInfo copy]];
}

#pragma mark - Helper Methods

+ (NSString *)defaultDescriptionForCode:(CLXErrorCode)code {
    switch (code) {
        // INITIALIZATION ERRORS (100-199)
        case CLXErrorCodeNotInitialized:
            return @"SDK not initialized";
        case CLXErrorCodeInitializationInProgress:
            return @"SDK initialization already in progress";
        case CLXErrorCodeNoAdaptersFound:
            return @"No ad network adapters found";
        case CLXErrorCodeInitializationTimeout:
            return @"SDK initialization timeout";
        case CLXErrorCodeInvalidAppKey:
            return @"Invalid app key provided";
        case CLXErrorCodeSDKDisabled:
            return @"SDK disabled by kill switch";
            
        // NETWORK ERRORS (200-299)
        case CLXErrorCodeNetworkError:
            return @"Network connectivity error";
        case CLXErrorCodeNetworkTimeout:
            return @"Network request timeout";
        case CLXErrorCodeInvalidResponse:
            return @"Invalid server response";
        case CLXErrorCodeServerError:
            return @"Server error occurred";
            
        // AD REQUEST/LOADING ERRORS (300-399)
        case CLXErrorCodeNoFill:
            return @"No ad fill available";
        case CLXErrorCodeInvalidRequest:
            return @"Invalid ad request parameters";
        case CLXErrorCodeInvalidPlacement:
            return @"Invalid placement ID";
        case CLXErrorCodeLoadTimeout:
            return @"Ad loading timeout";
        case CLXErrorCodeLoadFailed:
            return @"Ad failed to load";
        case CLXErrorCodeInvalidAd:
            return @"Invalid or corrupted ad content";
        case CLXErrorCodeTooManyRequests:
            return @"Too many ad requests - rate limited";
        case CLXErrorCodeRequestCancelled:
            return @"Ad request was cancelled";
        case CLXErrorCodeAdsDisabled:
            return @"Ads disabled by kill switch";
            
        // AD DISPLAY/SHOW ERRORS (400-499)
        case CLXErrorCodeAdNotReady:
            return @"Ad is not ready to be shown";
        case CLXErrorCodeAdAlreadyShown:
            return @"Ad has already been shown";
        case CLXErrorCodeAdExpired:
            return @"Ad has expired";
        case CLXErrorCodeInvalidViewController:
            return @"Invalid view controller for ad display";
        case CLXErrorCodeShowFailed:
            return @"Ad failed to show";
            
        // CONFIGURATION/SETUP ERRORS (500-599)
        case CLXErrorCodeInvalidAdUnit:
            return @"Invalid ad unit configuration";
        case CLXErrorCodePermissionDenied:
            return @"Required permissions not granted";
        case CLXErrorCodeUnsupportedAdFormat:
            return @"Ad format not supported";
        case CLXErrorCodeInvalidBannerView:
            return @"Invalid banner view";
        case CLXErrorCodeInvalidNativeView:
            return @"Invalid native view";
            
        default:
            return @"Unknown error occurred";
    }
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"CLXError: %ld - %@", (long)self.code, self.localizedDescription];
}

@end
