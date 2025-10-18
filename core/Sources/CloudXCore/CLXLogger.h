#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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

@end

NS_ASSUME_NONNULL_END 