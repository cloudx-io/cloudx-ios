//
// CLXError.m
// CloudXCore
//
// Industry-standard error codes following common ad SDK patterns
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

+ (instancetype)errorWithCode:(CLXErrorCode)code description:(NSString *)description underlyingError:(NSError *)underlyingError {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    return [self errorWithCode:code userInfo:userInfo];
}

+ (instancetype)errorWithCode:(CLXErrorCode)code underlyingError:(nullable NSError *)underlyingError {
    return [self errorWithCode:code description:[self defaultDescriptionForCode:code] underlyingError:underlyingError];
}

+ (instancetype)errorFromError:(NSError *)error withFallbackCode:(CLXErrorCode)fallbackCode {
    if (!error) {
        return nil;
    }
    
    // If already a CLXError, return as-is (no wrapping needed)
    if ([error isKindOfClass:[CLXError class]]) {
        return (CLXError *)error;
    }
    
    // Wrap NSError in CLXError, preserving the original error code and description
    // Use NSError's designated initializer to avoid casting NSInteger to CLXErrorCode
    NSString *description = error.localizedDescription ?: [self defaultDescriptionForCode:fallbackCode];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    userInfo[NSUnderlyingErrorKey] = error;
    
    return [[CLXError alloc] initWithDomain:CLXErrorDomain code:error.code userInfo:userInfo];
}

+ (instancetype)errorWithHTTPStatusCode:(NSInteger)httpStatusCode {
    return [self errorWithHTTPStatusCode:httpStatusCode serverMessage:nil];
}

+ (instancetype)errorWithHTTPStatusCode:(NSInteger)httpStatusCode serverMessage:(NSString *)serverMessage {
    CLXErrorCode code;
    NSString *description;

    if (httpStatusCode == 401) {
        code = CLXErrorCodeInvalidAppKey;
        description = @"Unauthorized - Invalid app key";
    } else if (httpStatusCode == 429) {
        code = CLXErrorCodeTooManyRequests;
        description = @"Too Many Requests - Rate limited";
    } else if (httpStatusCode >= 500) {
        code = CLXErrorCodeServerError;
        description = [NSString stringWithFormat:@"Server Error - HTTP %ld", (long)httpStatusCode];
    } else if (httpStatusCode >= 400) {
        code = CLXErrorCodeClientError;
        description = [NSString stringWithFormat:@"Client Error - HTTP %ld", (long)httpStatusCode];
    } else {
        code = CLXErrorCodeNetworkError;
        description = [NSString stringWithFormat:@"Network Error - HTTP %ld", (long)httpStatusCode];
    }
    
    // Build userInfo dictionary with server message if available
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    
    // Add server message as failure reason for detailed error reporting
    if (serverMessage && serverMessage.length > 0) {
        userInfo[NSLocalizedFailureReasonErrorKey] = serverMessage;
    }
    
    return [self errorWithCode:code userInfo:userInfo];
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
            return @"SDK not initialized. Please initialize the SDK before using it.";
        case CLXErrorCodeNoAdaptersFound:
            return @"No ad adapters found. Add at least one adapter to show ads.";
        case CLXErrorCodeNoNetworksConfigured:
            return @"No ad networks configured for this app.";
        case CLXErrorCodeInvalidAppKey:
            return @"Invalid app key.";
        case CLXErrorCodeSDKDisabled:
            return @"SDK is disabled by server configuration.";
            
        // NETWORK ERRORS (200-299)
        case CLXErrorCodeNetworkError:
            return @"Network error.";
        case CLXErrorCodeNetworkTimeout:
            return @"Network request timed out.";
        case CLXErrorCodeServerError:
            return @"Server error (5xx).";
        case CLXErrorCodeClientError:
            return @"Client error (4xx).";
        case CLXErrorCodeTooManyRequests:
            return @"Rate limited (429).";
        case CLXErrorCodeInvalidResponse:
            return @"Invalid or unparseable server response.";
            
        // AD REQUEST/LOADING ERRORS (300-399)
        case CLXErrorCodeNoFill:
            return @"No ad available to display.";
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
        case CLXErrorCodeRequestCancelled:
            return @"Ad request was cancelled.";
        case CLXErrorCodeAdsDisabled:
            return @"Ads are disabled by server configuration.";
            
        // AD DISPLAY/SHOW ERRORS (400-499)
        case CLXErrorCodeAdNotReady:
            return @"Ad is not ready to be displayed.";
        case CLXErrorCodeAdAlreadyShown:
            return @"Ad has already been displayed.";
        case CLXErrorCodeAdExpired:
            return @"Ad has expired and cannot be displayed.";
        case CLXErrorCodeInvalidViewController:
            return @"Invalid view controller provided for ad display.";
        case CLXErrorCodeShowFailed:
            return @"Failed to display ad.";
            
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
        case CLXErrorCodeNoAdaptersRegistered:
            return @"No ad network adapters registered. Please include adapter frameworks in your project.";
        case CLXErrorCodeInvalidConfiguration:
            return @"Invalid adapter configuration.";
        case CLXErrorCodeInvalidAdUnitID:
            return @"Invalid ad unit ID provided.";
        case CLXErrorCodeInvalidBidResponse:
            return @"Invalid bid response received.";
            
        // ADAPTER ERRORS (600-699)
        case CLXErrorCodeAdapterInternalError:
            return @"Internal error.";
        case CLXErrorCodeAdapterNoFill:
            return @"No fill.";
        case CLXErrorCodeAdapterInvalidLoadState:
            return @"Invalid load state.";
        case CLXErrorCodeAdapterInvalidConfiguration:
            return @"Invalid configuration.";
        case CLXErrorCodeAdapterInvalidServerExtras:
            return @"Invalid server parameters for adapter.";
        case CLXErrorCodeAdapterBadRequest:
            return @"Bad request.";
        case CLXErrorCodeAdapterNotInitialized:
            return @"Not initialized.";
        case CLXErrorCodeAdapterInitializationError:
            return @"Ad network SDK failed to initialize.";
        case CLXErrorCodeAdapterAdNotReady:
            return @"Ad not ready.";
        case CLXErrorCodeAdapterLoadTimeout:
            return @"Adapter load timed out.";
        case CLXErrorCodeAdapterTimeout:
            return @"Request timed out.";
        case CLXErrorCodeAdapterNoConnection:
            return @"No connection.";
        case CLXErrorCodeAdapterServerError:
            return @"Server error.";
        case CLXErrorCodeAdapterBidTokenTimeout:
            return @"Bid token collection timed out.";
        case CLXErrorCodeAdapterBidTokenNotSupported:
            return @"Bid token collection not supported.";
        case CLXErrorCodeAdapterWebViewError:
            return @"WebView error.";
        case CLXErrorCodeAdapterAdExpired:
            return @"Ad expired.";
        case CLXErrorCodeAdapterAdFrequencyCapped:
            return @"Ad frequency capped.";
        case CLXErrorCodeAdapterRewardError:
            return @"Reward error.";
        case CLXErrorCodeAdapterMissingNativeAdAssets:
            return @"Missing native ad assets.";
        case CLXErrorCodeAdapterMissingViewController:
            return @"Missing view controller.";
        case CLXErrorCodeAdapterDisplayFailed:
            return @"Ad display failed.";

        // GENERAL ERRORS (0)
        case CLXErrorCodeInternalError:
            return @"Internal error.";

        default:
            return @"Internal error.";
    }
}

#pragma mark - Properties

- (NSError *)underlyingError {
    return self.userInfo[NSUnderlyingErrorKey];
}

#pragma mark - NSObject

- (NSString *)description {
    NSString *baseDescription = [NSString stringWithFormat:@"CLXError: %ld - %@", (long)self.code, self.localizedDescription];
    NSError *underlying = self.underlyingError;
    if (underlying) {
        return [NSString stringWithFormat:@"%@ (caused by: %@)", baseDescription, underlying.localizedDescription];
    }
    return baseDescription;
}

@end

#pragma mark - NSError (CLXErrorFormatting)

@implementation NSError (CLXErrorFormatting)

- (NSString *)clx_fullErrorMessage {
    NSString *message = self.localizedDescription ?: @"Unknown error";
    
    // Append server details if available
    if (self.localizedFailureReason && self.localizedFailureReason.length > 0) {
        return [NSString stringWithFormat:@"%@ - %@", message, self.localizedFailureReason];
    }
    
    return message;
}

@end
