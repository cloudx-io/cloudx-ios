/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorReporter.m
 * @brief Implementation of SDK error reporting facade
 */

#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXMetricsTracker+ErrorTracking.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXErrorReporter ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXErrorReporter

+ (instancetype)shared {
    static CLXErrorReporter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"ErrorReporter"];
    }
    return self;
}

- (void)reportException:(NSException *)exception 
                context:(nullable NSDictionary<NSString *, NSString *> *)context {
    [self reportException:exception placementID:nil context:context];
}

- (void)reportError:(NSError *)error 
            context:(nullable NSDictionary<NSString *, NSString *> *)context {
    [self reportError:error placementID:nil context:context];
}

- (void)reportException:(NSException *)exception 
            placementID:(nullable NSString *)placementID
                context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    @try {
        if (!exception) {
            [self.logger debug:@"📊 [ErrorReporter] Attempted to report nil exception"];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [ErrorReporter] Reporting exception: %@ (placement: %@)", 
                          exception.name ?: @"unknown", placementID ?: @"global"]];
        
        // Route through metrics tracker for actual reporting
        [[CLXMetricsTracker shared] trackException:exception placementID:placementID context:context];
        
    } @catch (NSException *reportingException) {
        // ABSOLUTE SILENCE - cannot risk affecting business logic
        // Only log in debug builds to console for development
        #if DEBUG
        NSLog(@"[CLXErrorReporter] Error reporting failed silently: %@", reportingException.reason);
        #endif
    }
}

- (void)reportError:(NSError *)error 
        placementID:(nullable NSString *)placementID
            context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    @try {
        if (!error) {
            [self.logger debug:@"📊 [ErrorReporter] Attempted to report nil error"];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [ErrorReporter] Reporting error: %@ (placement: %@)", 
                          error.localizedDescription ?: @"unknown", placementID ?: @"global"]];
        
        // Route through metrics tracker for actual reporting
        [[CLXMetricsTracker shared] trackNSError:error placementID:placementID context:context];
        
    } @catch (NSException *reportingException) {
        // ABSOLUTE SILENCE - cannot risk affecting business logic
        // Only log in debug builds to console for development
        #if DEBUG
        NSLog(@"[CLXErrorReporter] Error reporting failed silently: %@", reportingException.reason);
        #endif
    }
}

#if DEBUG
- (void)testErrorReporting {
    [self.logger info:@"🧪 [ErrorReporter] Testing error reporting infrastructure"];
    
    // Create a test exception
    NSException *testException = [NSException exceptionWithName:@"CLXTestException" 
                                                         reason:@"This is a test exception to verify error reporting works" 
                                                       userInfo:@{@"test": @"true"}];
    
    // Report it with test context
    [self reportException:testException context:@{@"operation": @"infrastructure_test", @"test_mode": @"debug"}];
    
    // Create a test error
    NSError *testError = [NSError errorWithDomain:@"CLXTestErrorDomain" 
                                             code:12345 
                                         userInfo:@{NSLocalizedDescriptionKey: @"This is a test error to verify error reporting works"}];
    
    // Report it with test context
    [self reportError:testError context:@{@"operation": @"infrastructure_test", @"test_mode": @"debug"}];
    
    [self.logger info:@"✅ [ErrorReporter] Error reporting test completed"];
}
#endif

@end
