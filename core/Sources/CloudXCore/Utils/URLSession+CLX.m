#import <CloudXCore/URLSession+CLX.h>

@implementation NSURLSession (CloudX)

+ (NSURLSession *)cloudxSessionWithIdentifier:(NSString *)identifier {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.waitsForConnectivity = YES;    
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:config];
    urlSession.sessionDescription = [NSString stringWithFormat:@"cloudx.sdk.%@", identifier];
    return urlSession;
}

@end 
