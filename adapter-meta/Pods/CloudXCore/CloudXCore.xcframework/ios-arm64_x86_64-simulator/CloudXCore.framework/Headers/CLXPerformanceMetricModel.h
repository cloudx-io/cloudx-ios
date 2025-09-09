#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPerformanceMetricModel : NSManagedObject

@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, assign) int64_t impressionCount;
@property (nonatomic, assign) int64_t clickCount;
@property (nonatomic, assign) int64_t bidResponseCount;
@property (nonatomic, assign) int64_t adLoadCount;
@property (nonatomic, assign) double adLoadLatency;
@property (nonatomic, assign) double bidRequestLatency;
@property (nonatomic, assign) int64_t failToLoadAdCount;
@property (nonatomic, assign) int64_t closeCount;
@property (nonatomic, assign) double closeLatency;

@end

NS_ASSUME_NONNULL_END 