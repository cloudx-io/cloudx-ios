#import "CLXMintegralErrorHandler.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXMintegralErrorHandler

+ (NSError *)handleNetworkError:(NSError *)networkError
                     withLogger:(CLXLogger *)logger
                        context:(NSString *)context
                    placementID:(nullable NSString *)placementID {
    
    CLXErrorCode cloudXCode = CLXErrorCodeUnknown;
    NSString *description = networkError.localizedDescription ?: @"Unknown error";
    NSString *recoverySuggestion = nil;
    BOOL shouldRetry = NO;
    
    [logger error:[NSString stringWithFormat:@"%@ error for placement %@: %@", 
                   context, placementID ?: @"N/A", description]];
    
    NSInteger errorCode = networkError.code;
    
    if (errorCode == 1) {
        cloudXCode = CLXErrorCodeNoFill;
        description = @"No fill for ad request";
        shouldRetry = YES;
    } else if (errorCode == 2) {
        cloudXCode = CLXErrorCodeNetworkError;
        description = @"Network connectivity issue";
        shouldRetry = YES;
    } else if (errorCode == 3) {
        cloudXCode = CLXErrorCodeLoadFailed;
        description = @"Ad load failed";
        shouldRetry = YES;
    } else if (errorCode == 4) {
        cloudXCode = CLXErrorCodeInvalidConfiguration;
        description = @"Invalid configuration";
        shouldRetry = NO;
    } else {
        cloudXCode = CLXErrorCodeUnknown;
        description = [NSString stringWithFormat:@"Unknown error: %ld", (long)errorCode];
    }
    
    return [CLXError errorWithCode:cloudXCode
                       description:description
                recoverySuggestion:recoverySuggestion
                          userInfo:@{
                              NSUnderlyingErrorKey: networkError,
                              @"ShouldRetry": @(shouldRetry)
                          }];
}

@end

