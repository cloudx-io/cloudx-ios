/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXKeyValueState.h
 * @brief In-memory state manager for publisher-provided key-value pairs
 * @details Manages user and app-level key-value pairs that are injected
 * into bid requests at hardcoded paths (user.ext.data, app.ext.data).
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief In-memory state manager for key-value pairs
 * @discussion This singleton manages key-value pairs separately for user-level
 * and app-level targeting, similar to Android's SdkKeyValueState.
 */
@interface CLXKeyValueState : NSObject

/**
 * @brief Shared instance
 */
+ (instancetype)shared;

/**
 * @brief User-level key-value pairs
 * @discussion These are typically user-specific targeting parameters
 */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSString *> *userKeyValues;

/**
 * @brief App-level key-value pairs
 * @discussion These are typically app-specific targeting parameters
 */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSString *> *appKeyValues;

/**
 * @brief Hashed user ID
 */
@property (nonatomic, copy, nullable) NSString *hashedUserId;

/**
 * @brief Set a user-level key-value pair
 */
- (void)setUserKeyValue:(NSString *)key value:(NSString *)value;

/**
 * @brief Set an app-level key-value pair
 */
- (void)setAppKeyValue:(NSString *)key value:(NSString *)value;

/**
 * @brief Clear all key-value pairs
 */
- (void)clearAllKeyValues;

@end

NS_ASSUME_NONNULL_END
