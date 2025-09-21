#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CLXAppSessionModel, CLXSessionMetricModel, CLXInitMetricsModel, CLXPerformanceMetricModel, CLXAppSession, CLXInitMetrics;

NS_ASSUME_NONNULL_BEGIN

@interface CLXCoreDataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (readonly, strong) NSManagedObjectContext *viewContext;

+ (instancetype)shared;

- (void)saveContext;

- (NSArray *)fetch:(Class)objectClass;
- (CLXAppSessionModel *)fetchAppSessionWithSessionID:(NSString *)sessionID;
- (CLXSessionMetricModel *)fetchSessionMetricWithTimestamp:(NSDate *)timestamp;

- (void)createAppSessionWithSession:(CLXAppSession *)session;
- (void)createInitMetricsWithMetrics:(CLXInitMetrics *)metrics;

- (void)deleteObject:(NSManagedObject *)object;
- (void)deleteAll:(Class)objectClass;

- (void)updateAppSessionWithSession:(CLXAppSession *)session;
- (void)createOrGetPerformanceMetricForPlacementID:(NSString *)placementID
                                           session:(CLXAppSession *)session
                                        completion:(void (^)(CLXPerformanceMetricModel * _Nullable))completion;


@end

NS_ASSUME_NONNULL_END 