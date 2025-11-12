/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file NSDictionary+DynamicPath.h
 * @brief Category for injecting values at dynamic JSON paths
 * @details Provides functionality to set values in nested dictionaries
 * using dot-notation paths with array support (e.g., "user.ext.data" or "imp[*].ext.targeting")
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (DynamicPath)

/**
 * @brief Inject a value at a dynamic path in the dictionary
 * @param path Dot-notation path (e.g., "user.ext.data" or "imp[*].ext.targeting")
 * @param value The value to inject (dictionary, array, string, number, etc.)
 * @discussion Supports:
 * - Dot notation: "user.ext.data"
 * - Array indexing: "imp[0].ext"
 * - Array wildcards: "imp[*].ext" (applies to all array elements)
 * - Auto-creates intermediate objects/arrays as needed
 */
- (void)putAtDynamicPath:(NSString *)path value:(id)value;

@end

NS_ASSUME_NONNULL_END

