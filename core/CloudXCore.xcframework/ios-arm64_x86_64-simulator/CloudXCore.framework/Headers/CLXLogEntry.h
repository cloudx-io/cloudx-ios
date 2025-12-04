/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a single log entry captured by CLXLogStore.
 * Used for debugging when testMode is enabled.
 */
@interface CLXLogEntry : NSObject

@property (nonatomic, strong, readonly) NSDate *timestamp;
@property (nonatomic, assign, readonly) CLXLogLevel level;
@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, copy, readonly) NSString *message;

- (instancetype)initWithLevel:(CLXLogLevel)level
                     category:(NSString *)category
                      message:(NSString *)message;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns a formatted string representation of the log entry.
 * Format: "[HH:mm:ss.SSS] [LEVEL] category - message"
 */
- (NSString *)formattedString;

@end

NS_ASSUME_NONNULL_END

