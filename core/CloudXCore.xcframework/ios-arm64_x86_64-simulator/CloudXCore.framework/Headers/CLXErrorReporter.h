/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorReporter.h
 * @brief Facade for SDK error reporting and exception tracking
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Centralized facade for reporting SDK errors and exceptions
 * Provides a clean, safe interface for error tracking throughout the SDK
 * All error reporting is fail-safe and will never affect business logic
 */
@interface CLXErrorReporter : NSObject

/**
 * Returns the shared singleton instance of CLXErrorReporter
 * @return The shared CLXErrorReporter instance
 */
+ (instancetype)shared;

/**
 * Reports an NSException with optional context
 * This method is completely safe and will never throw or affect business logic
 * @param exception The exception that was caught
 * @param context Optional context dictionary with additional information
 */
- (void)reportException:(NSException *)exception 
                context:(nullable NSDictionary<NSString *, NSString *> *)context;

/**
 * Reports an NSError with optional context
 * This method is completely safe and will never throw or affect business logic
 * @param error The error that occurred
 * @param context Optional context dictionary with additional information
 */
- (void)reportError:(NSError *)error 
            context:(nullable NSDictionary<NSString *, NSString *> *)context;

/**
 * Reports an exception with placement context
 * @param exception The exception that was caught
 * @param placementID The placement ID where the exception occurred
 * @param context Optional additional context information
 */
- (void)reportException:(NSException *)exception 
            placementID:(nullable NSString *)placementID
                context:(nullable NSDictionary<NSString *, NSString *> *)context;

/**
 * Reports an error with placement context
 * @param error The error that occurred
 * @param placementID The placement ID where the error occurred
 * @param context Optional additional context information
 */
- (void)reportError:(NSError *)error 
        placementID:(nullable NSString *)placementID
            context:(nullable NSDictionary<NSString *, NSString *> *)context;

#if DEBUG
/**
 * Test method to verify error reporting infrastructure (DEBUG builds only)
 * This method creates a test exception and reports it to verify the system works
 */
- (void)testErrorReporting;
#endif

@end

NS_ASSUME_NONNULL_END
