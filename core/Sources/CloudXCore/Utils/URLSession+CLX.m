#import <CloudXCore/URLSession+CLX.h>

@implementation NSURLSession (CloudX)

+ (NSURLSession *)cloudxSessionWithIdentifier:(NSString *)identifier {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.waitsForConnectivity = YES;
    config.timeoutIntervalForRequest = 30.0;   // Match Android readTimeout
    config.timeoutIntervalForResource = 30.0;  // Match Android callTimeout
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    urlSession.sessionDescription = [NSString stringWithFormat:@"cloudx.sdk.%@", identifier];
    return urlSession;
}

@end 
