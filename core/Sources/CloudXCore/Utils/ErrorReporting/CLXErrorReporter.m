/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorReporter.m
 * @brief Implementation of SDK error reporting facade
 */

#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CloudXCore.h>

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
        
        // Create NSError from NSException for Rill tracking
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = exception.reason ?: @"Unknown exception";
        userInfo[@"exception_name"] = exception.name ?: @"UnknownException";
        
        // Add placement and context info
        if (placementID) {
            userInfo[@"placement_id"] = placementID;
        }
        if (context) {
            for (NSString *key in context.allKeys) {
                userInfo[[NSString stringWithFormat:@"context_%@", key]] = context[key];
            }
        }
        
        NSError *errorForTracking = [NSError errorWithDomain:@"CLXErrorReporter" 
                                                        code:1001 
                                                    userInfo:[userInfo copy]];
        
        // Send via Rill SDK Error tracking
        [CloudXCore trackSDKError:errorForTracking];
        
    } @catch (NSException *reportingException) {
        // ABSOLUTE SILENCE - cannot risk affecting business logic
        // No logging to avoid potential recursive issues in error handling
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
        
        // Enhance error with placement and context info for Rill tracking
        NSMutableDictionary *enhancedUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo ?: @{}];
        
        // Add placement and context info
        if (placementID) {
            enhancedUserInfo[@"placement_id"] = placementID;
        }
        if (context) {
            for (NSString *key in context.allKeys) {
                enhancedUserInfo[[NSString stringWithFormat:@"context_%@", key]] = context[key];
            }
        }
        
        NSError *enhancedError = [NSError errorWithDomain:error.domain 
                                                     code:error.code 
                                                 userInfo:[enhancedUserInfo copy]];
        
        // Send via Rill SDK Error tracking
        [CloudXCore trackSDKError:enhancedError];
        
    } @catch (NSException *reportingException) {
        // ABSOLUTE SILENCE - cannot risk affecting business logic
        // No logging to avoid potential recursive issues in error handling
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
