#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoAppLogEntry : NSObject
@property (nonatomic, strong, readonly) NSString *message;
@property (nonatomic, strong, readonly) NSDate *timestamp;
@property (nonatomic, strong, readonly) NSString *formattedTimestamp;

- (instancetype)initWithMessage:(NSString *)message;
@end

@interface DemoAppLogger : NSObject

+ (instancetype)sharedInstance;

- (void)logMessage:(NSString *)message;
- (void)clearLogs;
- (NSArray<DemoAppLogEntry *> *)getAllLogs;
- (NSInteger)logCount;

@end

NS_ASSUME_NONNULL_END
