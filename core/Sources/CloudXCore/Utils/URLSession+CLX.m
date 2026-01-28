#import <CloudXCore/URLSession+CLX.h>

@implementation NSURLSession (CloudX)

/**
 * Returns a shared NSURLSession configured for CloudX SDK network requests.
 *
 * This singleton is intentionally app-lifetime scoped. NSURLSession manages its own
 * connection pool and reuses connections efficiently. Invalidating the session would
 * cancel in-flight requests and provide no benefit for an SDK that runs for the app's
 * lifetime. This pattern matches Apple's own URLSession.shared.
 */
+ (NSURLSession *)cloudxSession {
    static NSURLSession *sharedSession;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Ephemeral config keeps data in memory only - no persistent cookies/cache
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];

        // Fail fast for ad requests - let service layer handle retries
        config.waitsForConnectivity = NO;

        // Timeouts aligned with Android SDK (30s read/call timeout)
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 30.0;

        // Disable caching - ad requests should always be fresh
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        config.URLCache = nil;

        // Isolate SDK from host app's cookies/credentials
        config.HTTPCookieStorage = nil;
        config.HTTPShouldSetCookies = NO;
        config.URLCredentialStorage = nil;

        sharedSession = [NSURLSession sessionWithConfiguration:config];
        sharedSession.sessionDescription = @"CloudX-SDK";
    });
    return sharedSession;
}

@end 
