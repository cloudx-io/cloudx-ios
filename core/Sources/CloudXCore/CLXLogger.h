#import <Foundation/Foundation.h>

@class CLXAd;
@class CLXError;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXLogLevel) {
    CLXLogLevelVerbose = 0,
    CLXLogLevelDebug = 1,
    CLXLogLevelInfo = 2,
    CLXLogLevelWarn = 3,
    CLXLogLevelError = 4
};

typedef NS_ENUM(NSInteger, CLXLogEmoji) {
    CLXLogEmojiError,     // ❌
    CLXLogEmojiWarn,      // ⚠️
    CLXLogEmojiInfo,      // ℹ️
    CLXLogEmojiDebug,     // 🐛
    CLXLogEmojiVerbose,   // 🔍
    CLXLogEmojiSuccess,   // ✅
    CLXLogEmojiEvent      // 🎉
};

@interface CLXLogger : NSObject

+ (instancetype)shared;

- (instancetype)initWithCategory:(NSString *)category;

// Log at specific level with automatic emoji mapping
- (void)verbose:(NSString *)message;
- (void)debug:(NSString *)message;
- (void)info:(NSString *)message;
- (void)warn:(NSString *)message;
- (void)error:(NSString *)message;

// Log at specific level with custom emoji type
- (void)logAtLevel:(CLXLogLevel)level 
         emojiType:(CLXLogEmoji)emojiType 
           message:(NSString *)message;

// Convenience methods (INFO level + custom emoji)
- (void)success:(NSString *)message;
- (void)event:(NSString *)message;

#pragma mark - Delegate Callback Logging

/**
 * Log a delegate callback at INFO level with formatted ad details.
 * These logs mirror the format used in demo apps for easy debugging.
 * @param callbackName The callback name with emoji (e.g., "✅ Banner didLoadAd")
 * @param ad The ad object to format details from (nullable for error callbacks)
 */
- (void)logDelegateCallback:(NSString *)callbackName ad:(nullable CLXAd *)ad;

/**
 * Log a delegate error callback at ERROR level with error details.
 * @param callbackName The callback name with emoji (e.g., "❌ Banner didFailToLoadAd")
 * @param error The error object with failure details
 */
- (void)logDelegateError:(NSString *)callbackName error:(nullable CLXError *)error;

/**
 * Enable or disable logging dynamically
 * @param enabled YES to enable logging, NO to disable
 */
- (void)setLoggingEnabled:(BOOL)enabled;

/**
 * Set the minimum log level. Messages below this level will be suppressed.
 * @param minLogLevel The minimum log level (CLXLogLevel)
 */
- (void)setMinLogLevel:(CLXLogLevel)minLogLevel;

/**
 * Enable or disable emojis in logs
 * @param enabled YES to show emojis (default), NO for plain text
 * @discussion Disable emojis when exporting logs to systems that don't support them
 */
- (void)setEmojisEnabled:(BOOL)enabled;

/**
 * Enable or disable timestamps in logs
 * @param enabled YES to show timestamps, NO to hide (default)
 * @discussion Timestamps are formatted as HH:mm:ss.SSS and appear after [CloudX]
 */
- (void)setTimestampsEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END 