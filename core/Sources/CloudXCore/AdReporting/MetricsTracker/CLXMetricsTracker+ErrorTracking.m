/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMetricsTracker+ErrorTracking.m
 * @brief Implementation of error tracking extension for CLXMetricsTracker
 */

#import <CloudXCore/CLXMetricsTracker+ErrorTracking.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXMetricsTracker (ErrorTracking)

- (void)trackError:(CLXErrorMetricType)errorType
       placementID:(nullable NSString *)placementID
           context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    @try {
        CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"ErrorTracking"];
        
        // Create error metric data
        NSString *errorTypeString = CLXErrorMetricTypeString(errorType);
        NSString *contextString = [self contextToString:context];
        
        [logger debug:[NSString stringWithFormat:@"📊 [ErrorTracking] Tracking error: %@ (placement: %@)", 
                      errorTypeString, placementID ?: @"none"]];
        
        // For now, we focus on comprehensive logging and reporting
        // Future enhancement: integrate with proper error metrics storage when available
        [logger debug:[NSString stringWithFormat:@"📊 [ErrorTracking] Error context: %@", contextString]];
        
        // For now, log the error details for debugging
        [logger info:[NSString stringWithFormat:@"🚨 [SDK Error] Type: %@, Placement: %@, Context: %@", 
                     errorTypeString, placementID ?: @"global", contextString]];
        
    } @catch (NSException *trackingException) {
        // Fail silently - error tracking must never affect business logic
        #if DEBUG
        NSLog(@"Error tracking failed: %@", trackingException.reason);
        #endif
    }
}

- (void)trackException:(NSException *)exception
           placementID:(nullable NSString *)placementID
               context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    if (!exception) {
        return;
    }
    
    @try {
        CLXErrorMetricType errorType = CLXErrorMetricTypeFromException(exception);
        
        // Enhance context with exception details
        NSMutableDictionary<NSString *, NSString *> *enhancedContext = [NSMutableDictionary dictionary];
        if (context) {
            [enhancedContext addEntriesFromDictionary:context];
        }
        
        enhancedContext[@"exception_name"] = exception.name ?: @"unknown";
        enhancedContext[@"exception_reason"] = exception.reason ?: @"no_reason";
        
        // Add first few stack trace entries for context
        if (exception.callStackSymbols && exception.callStackSymbols.count > 0) {
            NSArray *topFrames = [exception.callStackSymbols subarrayWithRange:NSMakeRange(0, MIN(3, exception.callStackSymbols.count))];
            enhancedContext[@"stack_trace"] = [topFrames componentsJoinedByString:@"|"];
        }
        
        [self trackError:errorType placementID:placementID context:[enhancedContext copy]];
        
    } @catch (NSException *trackingException) {
        // Fail silently - error tracking must never affect business logic
        #if DEBUG
        NSLog(@"Exception tracking failed: %@", trackingException.reason);
        #endif
    }
}

- (void)trackNSError:(NSError *)error
         placementID:(nullable NSString *)placementID
             context:(nullable NSDictionary<NSString *, NSString *> *)context {
    
    if (!error) {
        return;
    }
    
    @try {
        CLXErrorMetricType errorType = CLXErrorMetricTypeFromError(error);
        
        // Enhance context with error details
        NSMutableDictionary<NSString *, NSString *> *enhancedContext = [NSMutableDictionary dictionary];
        if (context) {
            [enhancedContext addEntriesFromDictionary:context];
        }
        
        enhancedContext[@"error_domain"] = error.domain ?: @"unknown";
        enhancedContext[@"error_code"] = [@(error.code) stringValue];
        enhancedContext[@"error_description"] = error.localizedDescription ?: @"no_description";
        
        [self trackError:errorType placementID:placementID context:[enhancedContext copy]];
        
    } @catch (NSException *trackingException) {
        // Fail silently - error tracking must never affect business logic
        #if DEBUG
        NSLog(@"NSError tracking failed: %@", trackingException.reason);
        #endif
    }
}

#pragma mark - Private Helpers

- (NSString *)contextToString:(nullable NSDictionary<NSString *, NSString *> *)context {
    if (!context || context.count == 0) {
        return @"{}";
    }
    
    @try {
        NSMutableArray *pairs = [NSMutableArray array];
        for (NSString *key in context.allKeys) {
            NSString *value = context[key] ?: @"null";
            [pairs addObject:[NSString stringWithFormat:@"%@:%@", key, value]];
        }
        return [NSString stringWithFormat:@"{%@}", [pairs componentsJoinedByString:@","]];
    } @catch (NSException *exception) {
        return @"{context_serialization_failed}";
    }
}

@end
