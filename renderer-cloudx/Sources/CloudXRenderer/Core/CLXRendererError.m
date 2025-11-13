//
//  CLXRendererError.m
//  CloudXRenderer
//
//  Renderer error handling implementation
//

#import "CLXRendererError.h"

NSString *const CLXRendererErrorDomain = @"com.cloudx.renderer";

@implementation CLXRendererError

+ (NSError *)errorWithCode:(CLXRendererErrorCode)code description:(NSString *)description {
    return [self errorWithCode:code description:description underlyingError:nil];
}

+ (NSError *)errorWithCode:(CLXRendererErrorCode)code 
               description:(NSString *)description 
           underlyingError:(nullable NSError *)underlyingError {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    userInfo[NSLocalizedFailureReasonErrorKey] = [self descriptionForCode:code];
    
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }
    
    return [NSError errorWithDomain:CLXRendererErrorDomain code:code userInfo:userInfo];
}

+ (NSString *)descriptionForCode:(CLXRendererErrorCode)code {
    switch (code) {
        // Configuration Errors
        case CLXRendererErrorCodeNotInitialized:
            return @"Renderer not initialized. Call initializeWithConfiguration: first.";
        case CLXRendererErrorCodeInvalidConfiguration:
            return @"Invalid Renderer configuration provided.";
        case CLXRendererErrorCodeInvalidServerURL:
            return @"Invalid Renderer server URL in configuration.";
            
        // Network Errors
        case CLXRendererErrorCodeNetworkFailure:
            return @"Network request failed to complete.";
        case CLXRendererErrorCodeRequestTimeout:
            return @"Bid request timed out waiting for server response.";
        case CLXRendererErrorCodeInvalidResponse:
            return @"Invalid response received from Renderer server.";
        case CLXRendererErrorCodeServerError:
            return @"Renderer server returned an error response.";
            
        // Bid Errors
        case CLXRendererErrorCodeNoBidResponse:
            return @"No valid bid received from demand sources.";
        case CLXRendererErrorCodeInvalidBidResponse:
            return @"Bid response format is invalid or corrupted.";
        case CLXRendererErrorCodeBidExpired:
            return @"Bid has expired and can no longer be rendered.";
        case CLXRendererErrorCodeInsufficientInventory:
            return @"No suitable inventory available for bid request.";
            
        // Rendering Errors
        case CLXRendererErrorCodeRenderingFailure:
            return @"Failed to render ad creative in web view.";
        case CLXRendererErrorCodeInvalidAdMarkup:
            return @"Ad creative markup is invalid or unsupported.";
        case CLXRendererErrorCodeWebViewError:
            return @"Web view encountered an error while loading ad.";
        case CLXRendererErrorCodeViewControllerNotAvailable:
            return @"Required view controller not available for presentation.";
            
        // Ad Format Errors
        case CLXRendererErrorCodeUnsupportedAdFormat:
            return @"Requested ad format is not supported.";
        case CLXRendererErrorCodeInvalidAdSize:
            return @"Ad size is invalid for the requested format.";
        case CLXRendererErrorCodeVideoPlaybackError:
            return @"Video ad failed to play or complete playback.";
        case CLXRendererErrorCodeNativeAdError:
            return @"Native ad component failed to load or render.";
            
        case CLXRendererErrorCodeUnknown:
        default:
            return @"An unknown error occurred in the Renderer.";
    }
}

+ (BOOL)isNetworkError:(NSError *)error {
    if (![error.domain isEqualToString:CLXRendererErrorDomain]) {
        return NO;
    }
    
    return (error.code >= 200 && error.code < 300);
}

+ (BOOL)isRenderingError:(NSError *)error {
    if (![error.domain isEqualToString:CLXRendererErrorDomain]) {
        return NO;
    }
    
    return (error.code >= 400 && error.code < 500);
}

@end