//
//  CLXMetaErrorHandler.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Centralized error handler for Meta Audience Network SDK errors
 * Provides comprehensive logging and error categorization for all FAN SDK error codes
 */
@interface CLXMetaErrorHandler : NSObject

/**
 * Processes and logs Meta FAN SDK errors with comprehensive details
 * @param error The NSError from Meta FAN SDK
 * @param logger The logger instance to use for logging
 * @param context Additional context (e.g., "Banner", "Interstitial", "Rewarded", "Native")
 * @param placementID The placement ID where the error occurred
 * @return Enhanced NSError with additional metadata
 */
+ (NSError *)handleMetaError:(NSError *)error
                  withLogger:(CLXLogger *)logger
                     context:(NSString *)context
                 placementID:(NSString *)placementID;

/**
 * Gets a human-readable description of the error code
 * @param errorCode The Meta FAN SDK error code
 * @return Descriptive string explaining the error
 */
+ (NSString *)descriptionForErrorCode:(NSInteger)errorCode;

/**
 * Gets user-friendly alert title and message for displaying to end users
 * @param error The NSError from Meta FAN SDK or CloudX system
 * @param context Additional context (e.g., "Banner", "Interstitial", "Rewarded", "Native")
 * @return Dictionary with @"title" and @"message" keys for user-friendly display
 */
+ (NSDictionary *)userFriendlyAlertInfoForError:(NSError *)error context:(NSString *)context;

/**
 * Gets a descriptive string for the current ATT authorization status
 * @return String describing the current ATT status (for debugging/logging)
 */
+ (NSString *)currentATTStatusDescription;

@end

NS_ASSUME_NONNULL_END
