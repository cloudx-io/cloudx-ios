//
//  CLXVungleErrorHandler.h
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Centralized error handler for Vungle SDK errors
 * Provides comprehensive logging and error categorization for all VungleAds SDK error codes
 */
@interface CLXVungleErrorHandler : NSObject

/**
 * Error domain for Vungle adapter errors
 */
extern NSString * const CLXVungleAdapterErrorDomain;

/**
 * Vungle adapter error codes
 */
typedef NS_ENUM(NSInteger, CLXVungleAdapterErrorCode) {
    CLXVungleAdapterErrorCodeInitializationFailed = 1000,
    CLXVungleAdapterErrorCodeLoadFailed = 1001,
    CLXVungleAdapterErrorCodeShowFailed = 1002,
    CLXVungleAdapterErrorCodeInvalidConfiguration = 1003,
    CLXVungleAdapterErrorCodeNotInitialized = 1004,
    CLXVungleAdapterErrorCodeNoFill = 1005,
    CLXVungleAdapterErrorCodeTimeout = 1006,
    CLXVungleAdapterErrorCodeNetworkError = 1007,
    CLXVungleAdapterErrorCodeInvalidPlacement = 1008,
    CLXVungleAdapterErrorCodeAdExpired = 1009
};

/**
 * Processes and logs Vungle SDK errors with comprehensive details
 * @param error The NSError from Vungle SDK
 * @param logger The logger instance to use for logging
 * @param context Additional context (e.g., "Banner", "Interstitial", "Rewarded", "Native")
 * @param placementID The placement ID where the error occurred
 * @return Enhanced NSError with additional metadata for rate limiting and retry logic
 */
+ (NSError *)handleVungleError:(NSError *)error
                    withLogger:(CLXLogger *)logger
                       context:(NSString *)context
                   placementID:(NSString *)placementID;

/**
 * Creates a CloudX-compatible error from Vungle error
 * @param vungleError The original Vungle SDK error
 * @param context Additional context information
 * @return CloudX error with mapped error code
 */
+ (NSError *)mapVungleError:(NSError *)vungleError context:(NSString *)context;

/**
 * Checks if the error indicates rate limiting and returns suggested delay
 * @param error The NSError from Vungle SDK
 * @return Suggested delay in seconds, or 0 if no delay needed
 */
+ (NSTimeInterval)suggestedDelayForError:(NSError *)error;

/**
 * Checks if the error is retryable (network issues, server errors)
 * @param error The NSError from Vungle SDK
 * @return YES if the error suggests retrying might succeed
 */
+ (BOOL)isRetryableError:(NSError *)error;

/**
 * Gets a human-readable description of the error code
 * @param errorCode The Vungle SDK error code
 * @return Descriptive string explaining the error
 */
+ (NSString *)descriptionForErrorCode:(NSInteger)errorCode;

/**
 * Gets user-friendly alert title and message for displaying to end users
 * @param error The NSError from Vungle SDK or CloudX system
 * @param context Additional context (e.g., "Banner", "Interstitial", "Rewarded", "Native")
 * @return Dictionary with @"title" and @"message" keys for user-friendly display
 */
+ (NSDictionary *)userFriendlyAlertInfoForError:(NSError *)error context:(NSString *)context;

@end

NS_ASSUME_NONNULL_END
