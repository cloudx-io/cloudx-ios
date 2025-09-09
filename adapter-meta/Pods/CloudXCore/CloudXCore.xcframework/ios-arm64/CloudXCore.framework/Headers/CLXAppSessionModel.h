#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SessionMetricModel;
@class PerformanceMetricModel;

NS_ASSUME_NONNULL_BEGIN

@interface CLXAppSessionModel : NSManagedObject

@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *appKey;
@property (nonatomic, copy, nullable) NSURL *url;
@property (nonatomic, assign) double duration;
@property (nonatomic, strong, nullable) NSSet<SessionMetricModel *> *metrics;
@property (nonatomic, strong, nullable) NSSet<PerformanceMetricModel *> *performanceMetrics;

@end

NS_ASSUME_NONNULL_END 