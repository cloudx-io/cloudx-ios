/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXLogEntry.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Thread-safe log storage with LRU eviction.
 * Automatically enabled when SDK is initialized with testMode:YES.
 * 
 * Stores up to 1000 log entries. When the limit is reached,
 * the oldest entries are removed to make room for new ones.
 */
@interface CLXLogStore : NSObject

/**
 * Maximum number of log entries to store.
 */
@property (class, nonatomic, readonly) NSUInteger maxLogEntries;

/**
 * Shared singleton instance.
 */
+ (instancetype)shared;

/**
 * Add a log entry to the store.
 * Thread-safe. If storage is disabled, this is a no-op.
 * @param entry The log entry to add.
 */
- (void)addEntry:(CLXLogEntry *)entry;

/**
 * Get all stored log entries, newest first.
 * @return Array of CLXLogEntry objects in reverse chronological order.
 */
- (NSArray<CLXLogEntry *> *)allEntries;

/**
 * Get the number of stored entries.
 */
- (NSUInteger)count;

/**
 * Clear all stored log entries.
 */
- (void)clear;

/**
 * Wait for all pending async operations to complete.
 * Useful in tests to ensure all log entries have been processed.
 */
- (void)flush;

/**
 * Export all logs as a single formatted string.
 * @return Formatted string with all log entries, newest first.
 */
- (NSString *)exportAsString;

/**
 * Check if log storage is currently enabled.
 * Storage is enabled when testMode is YES.
 */
- (BOOL)isEnabled;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

