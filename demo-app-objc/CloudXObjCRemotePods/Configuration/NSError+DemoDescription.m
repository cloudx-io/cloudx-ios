//
// NSError+DemoDescription.m
// CloudXObjCRemotePods
//
// Category for providing detailed, user-friendly error descriptions in the demo app
//

#import "NSError+DemoDescription.h"

@implementation NSError (DemoDescription)

- (NSString *)detailedDemoDescription {
    if (!self) {
        return @"Unknown error occurred";
    }
    
    NSMutableString *description = [NSMutableString string];
    
    // Main error description
    [description appendFormat:@"%@\n\n", self.localizedDescription];
    
    // Error details
    [description appendString:@"Error Details:\n"];
    [description appendFormat:@"• Code: %ld\n", (long)self.code];
    
    // Add domain if not generic
    if (![self.domain isEqualToString:@"NSCocoaErrorDomain"]) {
        [description appendFormat:@"• Domain: %@\n", self.domain];
    }
    
    // Special handling for CloudX error codes
    if ([self.domain isEqualToString:@"com.cloudx.sdk.error"]) {
        NSString *errorCodeName = [self cloudXErrorCodeName:self.code];
        if (errorCodeName) {
            [description appendFormat:@"• Error Type: %@\n", errorCodeName];
        }
    }
    
    // Add additional helpful info from userInfo
    NSDictionary *userInfo = self.userInfo;
    
    // Failure reason if available
    NSString *failureReason = userInfo[NSLocalizedFailureReasonErrorKey];
    if (failureReason.length > 0) {
        [description appendFormat:@"• Reason: %@\n", failureReason];
    }
    
    // Recovery suggestion if available
    NSString *recoverySuggestion = userInfo[NSLocalizedRecoverySuggestionErrorKey];
    if (recoverySuggestion.length > 0) {
        [description appendFormat:@"\nSuggested Action:\n%@", recoverySuggestion];
    }
    
    // Add kill switch specific message
    if (self.code == 204 || self.code == 301) { // CLXErrorCodeSDKDisabled or CLXErrorCodeAdsDisabled
        [description appendString:@"\n⚠️ Kill Switch Active: SDK or ads have been remotely disabled via traffic control."];
    }

    return [description copy];
}

- (NSString *)cloudXErrorCodeName:(NSInteger)code {
    // Map CloudX error codes to human-readable names
    switch (code) {
        // GENERAL ERRORS (0)
        case 0: return @"Internal Error";

        // NETWORK ERRORS (100-199)
        case 100: return @"Network Error";
        case 101: return @"Network Timeout";
        case 102: return @"Server Error";
        case 103: return @"Client Error";
        case 104: return @"Too Many Requests";
        case 105: return @"Invalid Response";
        case 106: return @"No Connection";

        // INITIALIZATION ERRORS (200-299)
        case 200: return @"Not Initialized";
        case 201: return @"No Adapters Found";
        case 202: return @"No Networks Configured";
        case 203: return @"Invalid App Key";
        case 204: return @"SDK Disabled (Kill Switch)";

        // AD REQUEST/LOADING ERRORS (300-399)
        case 300: return @"Invalid Ad Unit";
        case 301: return @"Ads Disabled (Kill Switch)";
        case 302: return @"No Fill";
        case 304: return @"Load Failed";

        // AD DISPLAY/SHOW ERRORS (400-499)
        case 400: return @"Ad Not Ready";
        case 401: return @"Ad Already Showing";

        // CONFIGURATION/SETUP ERRORS (500-599)
        case 500: return @"Invalid Native View";

        default: return nil;
    }
}

@end

