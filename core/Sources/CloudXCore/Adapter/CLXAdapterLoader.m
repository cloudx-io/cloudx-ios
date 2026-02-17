//
//  CLXAdapterLoader.m
//  CloudXCore
//
//  Centralized adapter loading utility with server-configured timeout.
//

#import "CLXAdapterLoader.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>

const int64_t CLXDefaultAdLoadTimeoutMs = 10000;

@implementation CLXAdapterLoader

+ (void)loadAdapter:(id)adapter
          timeoutMs:(int64_t)timeoutMs
     isLoadingBlock:(BOOL(^)(void))isLoadingBlock
          onTimeout:(void(^)(CLXError *error))onTimeout {

    // Use default if not set (matches Android default)
    NSTimeInterval seconds = (timeoutMs > 0) ? (timeoutMs / 1000.0) : (CLXDefaultAdLoadTimeoutMs / 1000.0);

    // Validate adapter before scheduling timeout
    if (![adapter respondsToSelector:@selector(load)]) {
        CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXAdapterLoader"];
        [logger error:[NSString stringWithFormat:@"Adapter %@ does not respond to -load selector", NSStringFromClass([adapter class])]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (onTimeout) {
                onTimeout([CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                                      description:[NSString stringWithFormat:@"Adapter %@ does not respond to -load", NSStringFromClass([adapter class])]]);
            }
        });
        return;
    }

    // Start timeout (fires on main queue)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (isLoadingBlock && isLoadingBlock()) {
            if (onTimeout) {
                CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterLoadTimeout
                                              description:[NSString stringWithFormat:@"Adapter load timed out after %.0fs", seconds]];
                onTimeout(error);
            }
        }
    });

    [adapter load];
}

@end
