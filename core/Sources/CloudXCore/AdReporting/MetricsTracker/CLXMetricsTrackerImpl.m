/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsTrackerImpl.h"
#import "CLXMetricsEventDao.h"
#import "CLXMetricsEvent.h"
#import "CLXMetricsConfig.h"
#import "CLXMetricsType.h"
#import "CLXEventTrackerBulkApi.h"
#import "CLXEventAM.h"
#import "CLXEventType.h"
#import "CLXPayloadBuilder.h"
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXMetricsDebugger.h>
#import <CloudXCore/CLXError.h>

@interface CLXMetricsTrackerImpl ()
@property (nonatomic, strong) CLXSQLiteDatabase *database;
@property (nonatomic, strong) CLXMetricsEventDao *metricsDao;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) CLXMetricsConfig *metricsConfig;
@property (nonatomic, strong) id<CLXEventTrackerBulkApi> bulkApi;
@property (nonatomic, assign) NSInteger sendIntervalSeconds;
@property (nonatomic, copy, nullable) NSString *endpoint;
@property (nonatomic, strong, nullable) NSTimer *sendTimer;
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, strong) CLXPayloadBuilder *payloadBuilder;
@property (nonatomic, strong) dispatch_queue_t metricsQueue;
@end

@implementation CLXMetricsTrackerImpl

- (instancetype)init {
    CLXSQLiteDatabase *database = [[CLXSQLiteDatabase alloc] initWithDatabaseName:@"cloudx_metrics"];
    return [self initWithDatabase:database];
}

- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database {
    id<CLXEventTrackerBulkApi> bulkApi = [[CLXEventTrackerBulkApiImpl alloc] initWithTimeoutMillis:10000];
    return [self initWithDatabase:database bulkApi:bulkApi payloadBuilder:nil];
}

- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database
                         bulkApi:(id<CLXEventTrackerBulkApi>)bulkApi {
    return [self initWithDatabase:database bulkApi:bulkApi payloadBuilder:nil];
}

- (instancetype)initWithPayloadBuilder:(CLXPayloadBuilder *)payloadBuilder {
    CLXSQLiteDatabase *database = [[CLXSQLiteDatabase alloc] initWithDatabaseName:@"cloudx_metrics"];
    id<CLXEventTrackerBulkApi> bulkApi = [[CLXEventTrackerBulkApiImpl alloc] initWithTimeoutMillis:10000];
    return [self initWithDatabase:database bulkApi:bulkApi payloadBuilder:payloadBuilder];
}

- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database
                         bulkApi:(id<CLXEventTrackerBulkApi>)bulkApi
                  payloadBuilder:(nullable CLXPayloadBuilder *)payloadBuilder {
    self = [super init];
    if (self) {
        _database = database;
        _metricsDao = [[CLXMetricsEventDao alloc] initWithDatabase:database];
        _logger = [[CLXLogger alloc] initWithCategory:@"MetricsTrackerImpl"];
        _bulkApi = bulkApi;
        _sendIntervalSeconds = 60;
        _sessionId = @"";
        _payloadBuilder = payloadBuilder;
        
        // Create serial queue for thread safety
        _metricsQueue = dispatch_queue_create("com.cloudx.metrics", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    // Capture timer reference and invalidate asynchronously on main thread
    // This is safe because NSTimer is thread-safe for invalidation
    NSTimer *timer = _sendTimer;
    _sendTimer = nil;
    
    if (timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [timer invalidate];
        });
    }
}

#pragma mark - CLXMetricsTrackerProtocol

- (void)startWithConfig:(CLXSDKConfig *)config {
    dispatch_async(self.metricsQueue, ^{
        self.metricsConfig = config.metricsConfig;
        if (!self.metricsConfig) {
            [self.logger info:@"📊 Metrics configuration is nil, metrics tracking DISABLED"];
            return;
        }
        
        // Use impressionTrackerURL for metrics with /bulk suffix
        NSString *metricsURL = config.impressionTrackerURL;
        if (metricsURL && metricsURL.length > 0) {
            self.endpoint = [NSString stringWithFormat:@"%@/bulk", metricsURL];
        } else {
            self.endpoint = nil;
            [self.logger info:@"📊 Metrics tracking enabled but NO ENDPOINT configured - events will be stored locally only"];
        }
        self.sendIntervalSeconds = self.metricsConfig.sendIntervalSeconds ?: 60;
        
        // Log config summary
        BOOL sdkApiEnabled = [self.metricsConfig isSdkApiCallsEnabled];
        BOOL networkEnabled = [self.metricsConfig isNetworkCallsEnabled];
        
        [self.logger info:[NSString stringWithFormat:@"📊 Metrics ENABLED (sdk_api=%@, network=%@, interval=%lds, endpoint=%@)",
                          sdkApiEnabled ? @"Y" : @"N",
                          networkEnabled ? @"Y" : @"N",
                          (long)self.sendIntervalSeconds,
                          self.endpoint ? @"configured" : @"NONE"]];
        
        [self _startPeriodicSending];
    });
}

- (void)trackMethodCall:(NSString *)methodType {
    if (![CLXMetricsType isMethodCallType:methodType]) {
        [self.logger error:[NSString stringWithFormat:@"Invalid method type: %@", methodType]];
        return;
    }
    
    dispatch_async(self.metricsQueue, ^{
        if (![self.metricsConfig isSdkApiCallsEnabled]) {
            return;
        }
        [self _trackMetric:methodType latency:0];
    });
}

- (void)trackNetworkCall:(NSString *)networkType latency:(NSInteger)latencyMs {
    [self trackNetworkCall:networkType latency:latencyMs error:nil];
}

- (void)trackNetworkCall:(NSString *)networkType latency:(NSInteger)latencyMs error:(nullable NSError *)error {
    if (![CLXMetricsType isNetworkCallType:networkType]) {
        [self.logger error:[NSString stringWithFormat:@"Invalid network type: %@", networkType]];
        return;
    }
    
    dispatch_async(self.metricsQueue, ^{
        BOOL isNetworkCallMetricsEnabled = [self.metricsConfig isNetworkCallsEnabled];
        BOOL isCallMetricsEnabled = NO;
        
        if ([networkType isEqualToString:CLXMetricsTypeNetworkSdkInit]) {
            isCallMetricsEnabled = [self.metricsConfig isSdkInitNetworkCallsEnabled];
        } else if ([networkType isEqualToString:CLXMetricsTypeNetworkGeoApi]) {
            isCallMetricsEnabled = [self.metricsConfig isGeoNetworkCallsEnabled];
        } else if ([networkType isEqualToString:CLXMetricsTypeNetworkBidRequest]) {
            isCallMetricsEnabled = [self.metricsConfig isBidRequestNetworkCallsEnabled];
        } else if ([networkType isEqualToString:CLXMetricsTypeNetworkTimeout] ||
                   [networkType isEqualToString:CLXMetricsTypeNetworkAdapterLoad] ||
                   [networkType isEqualToString:CLXMetricsTypeNetworkTimeToFirstAd]) {
            // Timeout, adapter load, and time-to-first-ad metrics follow network calls enabled setting
            isCallMetricsEnabled = YES;
        }
        
        if (isNetworkCallMetricsEnabled && isCallMetricsEnabled) {
            [self _trackMetric:networkType latency:latencyMs];
        }
        
        // If error is a timeout, also track the timeout metric
        if (error && isNetworkCallMetricsEnabled && [self _isTimeoutError:error]) {
            [self _trackMetric:CLXMetricsTypeNetworkTimeout latency:latencyMs];
        }
    });
}

- (BOOL)_isTimeoutError:(NSError *)error {
    if (!error) return NO;
    
    // Check NSURLError domain timeouts
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorTimedOut) {
        return YES;
    }
    
    // Check CloudX error codes for timeouts
    if ([error.domain isEqualToString:CLXErrorDomain]) {
        switch (error.code) {
            case CLXErrorCodeNetworkTimeout:
            case CLXErrorCodeAdapterTimeout:
                return YES;
            default:
                return NO;
        }
    }
    
    return NO;
}

- (void)trySendingPendingMetrics {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.metricsQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf _sendPendingMetrics];
        }
    });
}

- (void)stop {
    // Stop timer on main thread since that's where it was created
    // Use weak self to avoid retain cycle and zombie access
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf _stopPeriodicSending];
        }
    });
}

#pragma mark - Private Methods

- (void)_trackMetric:(NSString *)metricType latency:(NSInteger)latency {
    // Get existing metric for aggregation (matching Android logic)
    CLXMetricsEvent *existingMetric = [self.metricsDao getAllByMetric:metricType];
    
    CLXMetricsEvent *updatedMetric;
    if (!existingMetric) {
        updatedMetric = [[CLXMetricsEvent alloc] initWithEventId:[[NSUUID UUID] UUIDString]
                                                       sessionId:self.sessionId
                                                      metricName:metricType
                                                       auctionId:[[NSUUID UUID] UUIDString]];
        updatedMetric.counter = 1;
        updatedMetric.totalLatency = latency;
    } else {
        updatedMetric = [[CLXMetricsEvent alloc] initWithEventId:existingMetric.eventId
                                                       sessionId:existingMetric.sessionId
                                                      metricName:existingMetric.metricName
                                                       auctionId:existingMetric.auctionId];
        updatedMetric.counter = existingMetric.counter + 1;
        updatedMetric.totalLatency = existingMetric.totalLatency + latency;
    }
    
    [self.metricsDao insert:updatedMetric];
}

- (void)_startPeriodicSending {
    if (self.sendIntervalSeconds <= 0) {
        [self.logger info:@"Invalid send interval, periodic sending disabled"];
        return;
    }
    
    // Capture values needed in the block before dispatching
    NSInteger intervalSeconds = self.sendIntervalSeconds;
    __weak typeof(self) weakSelf = self;
    
    // Stop existing timer and create new one - both on main thread for thread safety
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // Stop existing timer on main thread where it was created
        [strongSelf _stopPeriodicSending];
        
        strongSelf.sendTimer = [NSTimer scheduledTimerWithTimeInterval:intervalSeconds
                                                         repeats:YES
                                                           block:^(NSTimer * _Nonnull timer) {
            __strong typeof(weakSelf) timerStrongSelf = weakSelf;
            if (!timerStrongSelf) {
                [timer invalidate];
                return;
            }
            // Dispatch back to the metrics queue for thread-safe metric sending
            dispatch_async(timerStrongSelf.metricsQueue, ^{
                __strong typeof(weakSelf) innerStrongSelf = weakSelf;
                if (innerStrongSelf) {
                    [innerStrongSelf _sendPendingMetrics];
                }
            });
        }];
    });
}

- (void)_stopPeriodicSending {
    if (self.sendTimer) {
        if ([self.sendTimer isValid]) {
            [self.sendTimer invalidate];
        }
        self.sendTimer = nil;
    }
}

- (void)_sendPendingMetrics {
    NSArray<CLXMetricsEvent *> *metrics = [self.metricsDao getAll];
    
    // If no endpoint or too many metrics, clean up old ones
    if (!self.endpoint || self.endpoint.length == 0 || metrics.count > 1000) {
        [self _cleanupOldMetrics];
        if (!self.endpoint || self.endpoint.length == 0) {
            return;
        }
        // Refresh metrics after cleanup
        metrics = [self.metricsDao getAll];
    }
    
    if (metrics.count == 0) {
        return;
    }
    
    // Convert metrics to EventAM objects
    NSMutableArray<CLXEventAM *> *events = [NSMutableArray arrayWithCapacity:metrics.count];
    for (CLXMetricsEvent *metric in metrics) {
        CLXEventAM *event = [self _buildEventFromMetric:metric];
        if (event) {
            [events addObject:event];
        } else {
            [self.logger error:[NSString stringWithFormat:@"Failed to build event for metric: %@", metric.metricName]];
        }
    }
    
    if (events.count == 0) {
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"Sending %lu metrics events to endpoint", (unsigned long)events.count]];
    
    // Send via bulk API - use weak self to avoid retain cycles
    __weak typeof(self) weakSelf = self;
    [self.bulkApi sendToEndpoint:self.endpoint items:events completion:^(BOOL success, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (success) {
            [strongSelf.logger info:[NSString stringWithFormat:@"Successfully sent %lu metrics events", (unsigned long)events.count]];
            
            // Delete successfully sent metrics
            dispatch_async(strongSelf.metricsQueue, ^{
                for (CLXMetricsEvent *metric in metrics) {
                    [strongSelf.metricsDao deleteById:metric.eventId];
                }
            });
        } else {
            [strongSelf.logger warn:[NSString stringWithFormat:@"Failed to send metrics: %@", error.localizedDescription ?: @"Unknown error"]];
        }
    }];
}

- (nullable CLXEventAM *)_buildEventFromMetric:(CLXMetricsEvent *)metric {
    if (!metric) {
        [self.logger error:@"Cannot build event - metric is nil"];
        return nil;
    }
    
    if (!self.payloadBuilder) {
        [self.logger error:@"Cannot build event - payloadBuilder is nil"];
        return nil;
    }
    
    NSString *accountId = self.payloadBuilder.accountId;
    if (!accountId || accountId.length == 0) {
        [self.logger error:@"Cannot build event - accountId is nil or empty"];
        return nil;
    }
    
    // Build payload using PayloadBuilder (matching Android architecture)
    // PayloadBuilder handles {eventId} placeholder replacement internally
    NSString *metricDetail = [NSString stringWithFormat:@"%ld/%ld", (long)metric.counter, (long)metric.totalLatency];
    NSString *auctionId = metric.auctionId ?: [[NSUUID UUID] UUIDString];
    
    NSString *payload = [self.payloadBuilder buildMetricPayloadWithEventId:auctionId
                                                                metricName:metric.metricName ?: @""
                                                              metricDetail:metricDetail];
    
    // Generate XOR encryption data matching Android exactly
    NSData *secret = [CLXXorEncryption generateXorSecret:accountId];
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64:accountId];
    NSString *impressionId = [CLXXorEncryption encrypt:payload secret:secret];
    
    // Use CLXEventTypePathSDKMetrics constant to match Android's EventType.SDK_METRICS.pathSegment
    return [[CLXEventAM alloc] initWithImpression:impressionId
                                       campaignId:campaignId
                                       eventValue:@"N/A"
                                        eventName:CLXEventTypePathSDKMetrics
                                             type:CLXEventTypePathSDKMetrics];
}

#pragma mark - Debug Methods

#ifdef DEBUG
- (void)debugPrintStatus {
    [CLXMetricsDebugger debugMetricsTracker:self];
    [CLXMetricsDebugger debugConfiguration:self.metricsConfig];
    [CLXMetricsDebugger printAllMetrics:self.metricsDao];
    
    // Additional debug info specific to this tracker instance
    NSString *accountId = self.payloadBuilder.accountId;
    [self.logger info:@"🔍 TRACKER INSTANCE DEBUG"];
    [self.logger info:@"========================="];
    [self.logger info:[NSString stringWithFormat:@"Session ID: %@", self.sessionId ?: @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"👤 Account ID: %@", accountId ?: @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"PayloadBuilder: %@", self.payloadBuilder ? @"configured" : @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"⏰ Send Timer: %@", self.sendTimer ? @"Active" : @"Inactive"]];
    
    // Performance report
    NSString *perfReport = [CLXMetricsDebugger generatePerformanceReport:self.metricsDao];
    [self.logger info:perfReport];
    
    // Encryption test
    if (accountId && accountId.length > 0) {
        NSString *encryptionTest = [CLXMetricsDebugger testEncryption:accountId];
        [self.logger info:encryptionTest];
    }
}

- (NSArray<NSString *> *)validateSystem {
    return [CLXMetricsDebugger validateMetricsSystem:self];
}

/**
 * Flush all pending async operations (testing only)
 * This method blocks until all pending trackMethodCall operations complete
 */
- (void)flushPendingOperations {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // Post a barrier block to the metrics queue to ensure all previous operations complete
    dispatch_async(self.metricsQueue, ^{
        // All previous async operations on metricsQueue will complete before this block executes
        dispatch_semaphore_signal(semaphore);
    });
    
    // Wait for the barrier block to execute (indicating all previous operations are done)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}
#endif

- (void)_cleanupOldMetrics {
    NSArray<CLXMetricsEvent *> *allMetrics = [self.metricsDao getAll];
    NSInteger originalCount = allMetrics.count;
    
    if (originalCount > 100) {
        // Sort by creation time and keep only the latest 100
        NSArray<CLXMetricsEvent *> *sortedMetrics = [allMetrics sortedArrayUsingComparator:^NSComparisonResult(CLXMetricsEvent *obj1, CLXMetricsEvent *obj2) {
            return [@(obj2.createdAt) compare:@(obj1.createdAt)]; // Descending order (newest first)
        }];
        
        // Delete all but the latest 100
        for (NSInteger i = 100; i < sortedMetrics.count; i++) {
            [self.metricsDao deleteById:sortedMetrics[i].eventId];
        }
    }
}

@end
