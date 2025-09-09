#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXLogger : NSObject

- (instancetype)initWithCategory:(NSString *)category;
- (void)debug:(NSString *)message;
- (void)info:(NSString *)message;
- (void)error:(NSString *)message;

@end

NS_ASSUME_NONNULL_END 