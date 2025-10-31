#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXLogLevel) {
    CLXLogLevelVerbose = 0,
    CLXLogLevelDebug = 1,
    CLXLogLevelInfo = 2,
    CLXLogLevelWarn = 3,
    CLXLogLevelError = 4
};

@interface CLXLogger : NSObject

+ (instancetype)shared;

- (instancetype)initWithCategory:(NSString *)category;
- (void)debug:(NSString *)message;
- (void)info:(NSString *)message;
- (void)error:(NSString *)message;

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

@end

NS_ASSUME_NONNULL_END 