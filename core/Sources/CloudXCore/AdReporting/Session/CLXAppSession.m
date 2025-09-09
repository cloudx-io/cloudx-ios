#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXCoreDataManager.h>
#import <CloudXCore/CLXSessionMetricSpend.h>
#import <CloudXCore/CLXSessionMetricPerformance.h>
#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXAppSessionModel.h>
#import <CloudXCore/CLXPerformanceMetricModel.h>

@interface CLXAppSession ()
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, strong) NSMutableArray<id<CLXSessionMetric>> *metrics;
@property (nonatomic, strong) NSMutableArray<CLXSessionMetricPerformance *> *performanceMetrics;
@property (nonatomic, assign) double sessionDuration;
@property (nonatomic, strong) NSTimer *sessionTimer;
@end

@implementation CLXAppSession

- (NSMutableArray<id<CLXSessionMetric>> *)metrics {
    return _metrics;
}

- (instancetype)initWithSessionID:(NSString *)sessionID 
                             url:(NSURL *)url 
                           appKey:(NSString *)appKey {
    self = [super init];
    if (self) {
        _sessionID = [sessionID copy];
        _startDate = [NSDate date];
        _url = url;
        _appKey = [appKey copy];
        _metrics = [NSMutableArray array];
        _performanceMetrics = [NSMutableArray array];
        _sessionDuration = 0;
        
        // Create CoreData session
        [[CLXCoreDataManager shared] createAppSessionWithSession:self];
        
        // Start session timer
        _sessionTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                         target:self
                                                       selector:@selector(updateSessionDuration)
                                                       userInfo:nil
                                                        repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_sessionTimer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (instancetype)initWithModel:(CLXAppSessionModel *)model {
    if (!model.id || !model.url || !model.appKey) {
        return nil;
    }
    
    self = [self initWithSessionID:model.id
                              url:[NSURL URLWithString:model.url]
                            appKey:model.appKey];
    
    if (self) {
        // Convert CoreData metrics to SessionMetricSpend objects
        if (model.metrics) {
            for (CLXSessionMetricModel *metricModel in model.metrics.allObjects) {
                CLXSessionMetricSpend *metricSpend = [[CLXSessionMetricSpend alloc] initWithMetricModel:metricModel];
                if (metricSpend) {
                    [self.metrics addObject:metricSpend];
                }
            }
        }
        
        self.sessionDuration = model.duration;
    }
    
    return self;
}

- (void)updateSessionDuration {
    if (!self) {
        [self.sessionTimer invalidate];
        return;
    }
    
    NSDate *currentDate = [NSDate date];
    self.sessionDuration = [currentDate timeIntervalSinceDate:self.startDate];
    [[CLXCoreDataManager shared] updateAppSessionWithSession:self];
}

- (void)addSpendWithPlacementID:(NSString *)placementID spend:(double)spend {
    CLXSessionMetricSpend *metric = [[CLXSessionMetricSpend alloc] initWithPlacementID:placementID
                                                                                                                                                           type:CLXSessionMetricTypeSpend
                                                                             value:spend
                                                                          timestamp:[NSDate date]];
    [self.metrics addObject:metric];
    [[CLXCoreDataManager shared] updateAppSessionWithSession:self];
}

- (void)addClickWithPlacementID:(NSString *)placementID {
    [[CLXCoreDataManager shared] createOrGetPerformanceMetricForPlacementID:placementID 
                                                                   session:self 
                                                               completion:^(CLXPerformanceMetricModel *metric) {
        if (metric) {
            metric.clickCount += 1;
            [[CLXCoreDataManager shared] saveContext];
        }
    }];
}

- (void)addImpressionWithPlacementID:(NSString *)placementID {
    [[CLXCoreDataManager shared] createOrGetPerformanceMetricForPlacementID:placementID 
                                                                   session:self 
                                                               completion:^(CLXPerformanceMetricModel *metric) {
        if (metric) {
            metric.impressionCount += 1;
            [[CLXCoreDataManager shared] saveContext];
        }
    }];
}

- (void)addCloseWithPlacementID:(NSString *)placementID latency:(double)latency {
    [[CLXCoreDataManager shared] createOrGetPerformanceMetricForPlacementID:placementID 
                                                                   session:self 
                                                               completion:^(CLXPerformanceMetricModel *metric) {
        if (metric) {
            metric.closeCount += 1;
            metric.closeLatency += latency;
            [[CLXCoreDataManager shared] saveContext];
        }
    }];
}

- (void)adFailedToLoadWithPlacementID:(NSString *)placementID {
    [[CLXCoreDataManager shared] createOrGetPerformanceMetricForPlacementID:placementID 
                                                                   session:self 
                                                               completion:^(CLXPerformanceMetricModel *metric) {
        if (metric) {
            metric.failToLoadAdCount += 1;
            [[CLXCoreDataManager shared] saveContext];
        }
    }];
}

- (void)bidLoadedWithPlacementID:(NSString *)placementID latency:(double)latency {
    [[CLXCoreDataManager shared] createOrGetPerformanceMetricForPlacementID:placementID 
                                                                   session:self 
                                                               completion:^(CLXPerformanceMetricModel *metric) {
        if (metric) {
            metric.bidResponseCount += 1;
            metric.bidRequestLatency += latency;
            [[CLXCoreDataManager shared] saveContext];
        }
    }];
}

- (void)adLoadedWithPlacementID:(NSString *)placementID latency:(double)latency {
    [[CLXCoreDataManager shared] createOrGetPerformanceMetricForPlacementID:placementID 
                                                                   session:self 
                                                               completion:^(CLXPerformanceMetricModel *metric) {
        if (metric) {
            metric.adLoadCount += 1;
            metric.adLoadLatency += latency;
            [[CLXCoreDataManager shared] saveContext];
        }
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SessionID: %@, StartDate: %@, Metrics: %@", 
            self.sessionID, self.startDate, self.metrics];
}

- (void)dealloc {
    [self.sessionTimer invalidate];
    self.sessionTimer = nil;
}

@end 
