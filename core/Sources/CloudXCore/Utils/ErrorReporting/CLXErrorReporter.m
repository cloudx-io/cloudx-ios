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

// Forward declaration of internal CloudXCore method
// Declared in CloudXCoreInternal.h but not importing to avoid module issues
@interface CloudXCore (ErrorReporting)
+ (void)trackSDKError:(NSError *)error;
@end

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
    [self reportException:exception adUnitId:nil context:context];
}

- (void)reportError:(NSError *)error 
            context:(nullable NSDictionary<NSString *, NSString *> *)context {
    [self reportError:error adUnitId:nil context:context];
}

- (void)reportException:(NSException *)exception 
               adUnitId:(nullable NSString *)adUnitId
                context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    @try {
        if (!exception) {
            [self.logger debug:@"Attempted to report nil exception"];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"Reporting exception: %@ (adUnit: %@)", 
                          exception.name ?: @"unknown", adUnitId ?: @"global"]];
        
        // Create NSError from NSException for Analytics tracking
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = exception.reason ?: @"Unknown exception";
        userInfo[@"exception_name"] = exception.name ?: @"UnknownException";
        
        // Add ad unit and context info
        if (adUnitId) {
            userInfo[@"ad_unit_id"] = adUnitId;
        }
        if (context) {
            for (NSString *key in context.allKeys) {
                userInfo[[NSString stringWithFormat:@"context_%@", key]] = context[key];
            }
        }
        
        NSError *errorForTracking = [NSError errorWithDomain:@"CLXErrorReporter" 
                                                        code:1001 
                                                    userInfo:[userInfo copy]];
        
        // Send via Analytics SDK Error tracking
        [CloudXCore trackSDKError:errorForTracking];
        
    } @catch (NSException *reportingException) {
        // ABSOLUTE SILENCE - cannot risk affecting business logic
        // No logging to avoid potential recursive issues in error handling
    }
}

- (void)reportError:(NSError *)error 
           adUnitId:(nullable NSString *)adUnitId
            context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    @try {
        if (!error) {
            [self.logger debug:@"Attempted to report nil error"];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"Reporting error: %@ (adUnit: %@)", 
                          error.localizedDescription ?: @"unknown", adUnitId ?: @"global"]];
        
        // Enhance error with ad unit and context info for Analytics tracking
        NSMutableDictionary *enhancedUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo ?: @{}];
        
        // Add ad unit and context info
        if (adUnitId) {
            enhancedUserInfo[@"ad_unit_id"] = adUnitId;
        }
        if (context) {
            for (NSString *key in context.allKeys) {
                enhancedUserInfo[[NSString stringWithFormat:@"context_%@", key]] = context[key];
            }
        }
        
        NSError *enhancedError = [NSError errorWithDomain:error.domain 
                                                     code:error.code 
                                                 userInfo:[enhancedUserInfo copy]];
        
        // Send via Analytics SDK Error tracking
        [CloudXCore trackSDKError:enhancedError];
        
    } @catch (NSException *reportingException) {
        // ABSOLUTE SILENCE - cannot risk affecting business logic
        // No logging to avoid potential recursive issues in error handling
    }
}

#if DEBUG
- (void)testErrorReporting {
    [self.logger debug:@"[ErrorReporter] Testing error reporting infrastructure"];
    
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
    
    [self.logger info:@"Error reporting test completed"];
}
#endif

@end
