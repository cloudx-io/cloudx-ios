#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInitMetricsModel : NSManagedObject

@property (nullable, nonatomic, copy) NSString *appKey;
@property (nullable, nonatomic, copy) NSDate *startedAt;
@property (nullable, nonatomic, copy) NSDate *endedAt;
@property (nonatomic) BOOL success;
@property (nullable, nonatomic, copy) NSString *sessionId;

@end

NS_ASSUME_NONNULL_END 