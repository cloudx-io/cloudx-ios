#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXCloudXDatabase.h>
#import <CloudXCore/CLXSession.h>
#import <CloudXCore/CLXPerformanceMetric.h>
#import <CloudXCore/CLXSessionMetricSpend.h>
#import <CloudXCore/CLXSessionMetricPerformance.h>
#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXDaoProtocols.h>

@interface CLXAppSession ()
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, strong) NSMutableArray<id<CLXSessionMetric>> *metrics;
@property (nonatomic, strong) NSMutableArray<CLXSessionMetricPerformance *> *performanceMetrics;
@property (nonatomic, assign) double sessionDuration;
@property (nonatomic, strong) NSTimer *sessionTimer;
@property (nonatomic, strong) CLXSession *sqliteSession;
@property (nonatomic, strong) CLXCloudXDatabase *database;
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
        _database = [CLXCloudXDatabase sharedInstance];
        
        // Create SQLite session
        _sqliteSession = [[CLXSession alloc] initWithSessionId:sessionID appKey:appKey url:url.absoluteString];
        [_sqliteSession startSession];
        [_database.sessionDao insertSession:_sqliteSession];
        
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

- (instancetype)initWithSession:(CLXSession *)session {
    if (!session.sessionId || !session.appKey) {
        return nil;
    }
    
    // Initialize directly without calling initWithSessionID to avoid duplicate session creation
    self = [super init];
    if (self) {
        NSURL *url = session.url ? [NSURL URLWithString:session.url] : nil;
        _sessionID = [session.sessionId copy];
        _startDate = [NSDate dateWithTimeIntervalSince1970:session.startTime];
        _url = url;
        _appKey = [session.appKey copy];
        _metrics = [NSMutableArray array];
        _performanceMetrics = [NSMutableArray array];
        _sessionDuration = session.duration;
        _database = [CLXCloudXDatabase sharedInstance];
        
        // Use existing SQLite session - don't insert again
        _sqliteSession = session;
        
        // Update duration from session
        [session updateDuration];
        self.sessionDuration = session.duration;
        
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

- (void)updateSessionDuration {
    if (!self) {
        [self.sessionTimer invalidate];
        return;
    }
    
    NSDate *currentDate = [NSDate date];
    self.sessionDuration = [currentDate timeIntervalSinceDate:self.startDate];
    
    // Update SQLite session
    [self.sqliteSession updateDuration];
    [self.database.sessionDao updateSessionDuration:self.sqliteSession.sessionId duration:self.sqliteSession.duration];
}

- (void)addSpendWithPlacementID:(NSString *)placementID spend:(double)spend {
    CLXSessionMetricSpend *metric = [[CLXSessionMetricSpend alloc] initWithPlacementID:placementID
                                                                                   type:CLXSessionMetricTypeSpend
                                                                                  value:spend
                                                                              timestamp:[NSDate date]];
    [self.metrics addObject:metric];
    
    // Update SQLite session duration
    [self.sqliteSession updateDuration];
    [self.database.sessionDao updateSessionDuration:self.sqliteSession.sessionId duration:self.sqliteSession.duration];
}

- (void)addClickWithPlacementID:(NSString *)placementID {
    CLXPerformanceMetric *metric = [self.database.performanceDao findOrCreatePerformanceMetricForPlacementId:placementID sessionId:self.sessionID];
    if (metric) {
        [metric incrementClicks];
        [self.database.performanceDao update:metric];
    }
}

- (void)addImpressionWithPlacementID:(NSString *)placementID {
    CLXPerformanceMetric *metric = [self.database.performanceDao findOrCreatePerformanceMetricForPlacementId:placementID sessionId:self.sessionID];
    if (metric) {
        [metric incrementImpressions];
        [self.database.performanceDao update:metric];
    }
}

- (void)addCloseWithPlacementID:(NSString *)placementID latency:(double)latency {
    CLXPerformanceMetric *metric = [self.database.performanceDao findOrCreatePerformanceMetricForPlacementId:placementID sessionId:self.sessionID];
    if (metric) {
        [metric incrementCloses];
        [metric addCloseLatency:latency];
        [self.database.performanceDao update:metric];
    }
}

- (void)adFailedToLoadWithPlacementID:(NSString *)placementID {
    CLXPerformanceMetric *metric = [self.database.performanceDao findOrCreatePerformanceMetricForPlacementId:placementID sessionId:self.sessionID];
    if (metric) {
        [metric incrementFailToLoadAds];
        [self.database.performanceDao update:metric];
    }
}

- (void)bidLoadedWithPlacementID:(NSString *)placementID latency:(double)latency {
    CLXPerformanceMetric *metric = [self.database.performanceDao findOrCreatePerformanceMetricForPlacementId:placementID sessionId:self.sessionID];
    if (metric) {
        [metric incrementBidResponses];
        [metric addBidRequestLatency:latency];
        [self.database.performanceDao update:metric];
    }
}

- (void)adLoadedWithPlacementID:(NSString *)placementID latency:(double)latency {
    CLXPerformanceMetric *metric = [self.database.performanceDao findOrCreatePerformanceMetricForPlacementId:placementID sessionId:self.sessionID];
    if (metric) {
        [metric incrementAdLoads];
        [metric addAdLoadLatency:latency];
        [self.database.performanceDao update:metric];
    }
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
