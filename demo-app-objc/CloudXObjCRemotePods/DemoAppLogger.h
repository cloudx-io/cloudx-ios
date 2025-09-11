#import <Foundation/Foundation.h>

@class CLXAd;

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
- (void)logAdEvent:(NSString *)eventName ad:(nullable CLXAd *)ad;
- (void)clearLogs;
- (NSArray<DemoAppLogEntry *> *)getAllLogs;
- (NSInteger)logCount;

// Helper method to format CLXAd details
+ (NSString *)formatAdDetails:(nullable CLXAd *)ad;

@end

NS_ASSUME_NONNULL_END
