/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXLossReasonMapper.h
 * @brief Utility class for mapping CLXErrorCode to CLXLossReason
 *
 * Centralizes error-to-loss-reason mapping following the DRY principle.
 * Used by publisher ad classes to categorize loss reasons for Win/Loss tracking.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for mapping CLXErrorCode to CLXLossReason.
 * Centralizes error-to-loss-reason mapping (DRY principle).
 *
 * This mapper enables categorized no-bid reason tracking by converting
 * SDK error codes into appropriate OpenRTB-compatible loss reasons.
 */
@interface CLXLossReasonMapper : NSObject

/**
 * Maps an NSError to the appropriate CLXLossReason.
 *
 * @param error The error to map (may be CLXError or any NSError)
 * @return The appropriate CLXLossReason for the error, or CLXLossReasonInternalError if error is nil or unmapped
 */
+ (CLXLossReason)lossReasonFromError:(nullable NSError *)error;

/**
 * Maps a CLXErrorCode to the appropriate CLXLossReason.
 *
 * @param errorCode The CLXErrorCode to map
 * @return The appropriate CLXLossReason for the error code
 */
+ (CLXLossReason)lossReasonFromErrorCode:(CLXErrorCode)errorCode;

@end

NS_ASSUME_NONNULL_END
