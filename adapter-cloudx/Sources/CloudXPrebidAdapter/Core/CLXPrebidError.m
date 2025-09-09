//
//  CLXPrebidError.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 error handling implementation
//

#import "CLXPrebidError.h"

NSString *const CLXPrebidErrorDomain = @"com.cloudx.prebid";

@implementation CLXPrebidError

+ (NSError *)errorWithCode:(CLXPrebidErrorCode)code description:(NSString *)description {
    return [self errorWithCode:code description:description underlyingError:nil];
}

+ (NSError *)errorWithCode:(CLXPrebidErrorCode)code 
               description:(NSString *)description 
           underlyingError:(nullable NSError *)underlyingError {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    userInfo[NSLocalizedFailureReasonErrorKey] = [self descriptionForCode:code];
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:CLXPrebidErrorDomain code:code userInfo:userInfo];
}

+ (NSString *)descriptionForCode:(CLXPrebidErrorCode)code {
    switch (code) {
        // Configuration Errors
        case CLXPrebidErrorCodeNotInitialized:
            return @"Prebid adapter not initialized. Call initializeWithConfiguration: first.";
        case CLXPrebidErrorCodeInvalidConfiguration:
            return @"Invalid Prebid configuration provided.";
        case CLXPrebidErrorCodeInvalidPrebidServerURL:
            return @"Invalid Prebid server URL in configuration.";
            
        // Network Errors
        case CLXPrebidErrorCodeNetworkFailure:
            return @"Network request failed to complete.";
        case CLXPrebidErrorCodeRequestTimeout:
            return @"Bid request timed out waiting for server response.";
        case CLXPrebidErrorCodeInvalidResponse:
            return @"Invalid response received from Prebid server.";
        case CLXPrebidErrorCodeServerError:
            return @"Prebid server returned an error response.";
            
        // Bid Errors
        case CLXPrebidErrorCodeNoBidResponse:
            return @"No valid bid received from demand sources.";
        case CLXPrebidErrorCodeInvalidBidResponse:
            return @"Bid response format is invalid or corrupted.";
        case CLXPrebidErrorCodeBidExpired:
            return @"Bid has expired and can no longer be rendered.";
        case CLXPrebidErrorCodeInsufficientInventory:
            return @"No suitable inventory available for bid request.";
            
        // Rendering Errors
        case CLXPrebidErrorCodeRenderingFailure:
            return @"Failed to render ad creative in web view.";
        case CLXPrebidErrorCodeInvalidAdMarkup:
            return @"Ad creative markup is invalid or unsupported.";
        case CLXPrebidErrorCodeWebViewError:
            return @"Web view encountered an error while loading ad.";
        case CLXPrebidErrorCodeViewControllerNotAvailable:
            return @"Required view controller not available for presentation.";
            
        // Ad Format Errors
        case CLXPrebidErrorCodeUnsupportedAdFormat:
            return @"Requested ad format is not supported.";
        case CLXPrebidErrorCodeInvalidAdSize:
            return @"Ad size is invalid for the requested format.";
        case CLXPrebidErrorCodeVideoPlaybackError:
            return @"Video ad failed to play or complete playback.";
        case CLXPrebidErrorCodeNativeAdError:
            return @"Native ad component failed to load or render.";
            
        case CLXPrebidErrorCodeUnknown:
        default:
            return @"An unknown error occurred in the Prebid adapter.";
    }
}

+ (BOOL)isNetworkError:(NSError *)error {
    if (![error.domain isEqualToString:CLXPrebidErrorDomain]) {
        return NO;
    }
    
    return (error.code >= 200 && error.code < 300);
}

+ (BOOL)isRenderingError:(NSError *)error {
    if (![error.domain isEqualToString:CLXPrebidErrorDomain]) {
        return NO;
    }
    
    return (error.code >= 400 && error.code < 500);
}

@end