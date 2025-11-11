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
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXMetricsDebugger.h>

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
@property (nonatomic, copy) NSString *basePayload;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, strong) dispatch_queue_t metricsQueue;
@end

@implementation CLXMetricsTrackerImpl

- (instancetype)init {
    CLXSQLiteDatabase *database = [[CLXSQLiteDatabase alloc] initWithDatabaseName:@"cloudx_metrics"];
    return [self initWithDatabase:database];
}

- (instancetype)initWithDatabase:(CLXSQLiteDatabase *)database {
    self = [super init];
    if (self) {
        _database = database;
        _metricsDao = [[CLXMetricsEventDao alloc] initWithDatabase:database];
        _logger = [[CLXLogger alloc] initWithCategory:@"MetricsTrackerImpl"];
        _bulkApi = [[CLXEventTrackerBulkApiImpl alloc] initWithTimeoutMillis:10000]; // 10 second timeout like Android
        _sendIntervalSeconds = 60; // Default like Android
        _sessionId = @"";
        _basePayload = @"";
        _accountId = @"";
        
        // Create serial queue for thread safety
        _metricsQueue = dispatch_queue_create("com.cloudx.metrics", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    // Synchronously stop without using dispatch queue to avoid crashes
    [self _stopPeriodicSending];
}

#pragma mark - CLXMetricsTrackerProtocol

- (void)startWithConfig:(CLXSDKConfig *)config {
    dispatch_async(self.metricsQueue, ^{
        self.metricsConfig = config.metricsConfig;
        if (!self.metricsConfig) {
            [self.logger info:@"Metrics configuration is nil, skipping metrics tracking"];
            return;
        }
        
        // Use impressionTrackerURL for metrics like Android uses trackingEndpointUrl
        NSString *metricsURL = config.impressionTrackerURL ?: config.metricsEndpointURL;
        if (metricsURL && metricsURL.length > 0) {
            self.endpoint = [NSString stringWithFormat:@"%@/bulk?debug=true", metricsURL];
        } else {
            self.endpoint = nil;
            [self.logger info:@"No impression tracker or metrics endpoint URL provided, metrics sending disabled"];
        }
        self.sendIntervalSeconds = self.metricsConfig.sendIntervalSeconds ?: 60;
        
        [self _startPeriodicSending];
    });
}

- (void)setBasicDataWithSessionId:(NSString *)sessionId 
                        accountId:(NSString *)accountId 
                      basePayload:(NSString *)basePayload {
    dispatch_async(self.metricsQueue, ^{
        self.sessionId = [sessionId copy] ?: @"";
        self.accountId = [accountId copy] ?: @"";
        self.basePayload = [basePayload copy] ?: @"";
    });
}

- (void)trackMethodCall:(NSString *)methodType {
    if (![CLXMetricsType isMethodCallType:methodType]) {
        [self.logger error:[NSString stringWithFormat:@"Invalid method type: %@", methodType]];
        return;
    }
    
    dispatch_async(self.metricsQueue, ^{
        // Check if SDK API calls are enabled
        BOOL isMethodCallMetricsEnabled = [self.metricsConfig isSdkApiCallsEnabled];
        if (!isMethodCallMetricsEnabled) {
            return;
        }
        
        [self _trackMetric:methodType latency:0];
    });
}

- (void)trackNetworkCall:(NSString *)networkType latency:(NSInteger)latencyMs {
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
        }
        
        if (isNetworkCallMetricsEnabled && isCallMetricsEnabled) {
            [self _trackMetric:networkType latency:latencyMs];
        }
    });
}

- (void)trySendingPendingMetrics {
    dispatch_async(self.metricsQueue, ^{
        [self _sendPendingMetrics];
    });
}

- (void)stop {
    if (self.metricsQueue) {
        dispatch_async(self.metricsQueue, ^{
            [self _stopPeriodicSending];
        });
    } else {
        // Fallback for cases where queue is not available
        [self _stopPeriodicSending];
    }
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
    [self _stopPeriodicSending]; // Stop any existing timer
    
    if (self.sendIntervalSeconds <= 0) {
        [self.logger info:@"Invalid send interval, periodic sending disabled"];
        return;
    }
    
    // Use weak reference to avoid retain cycle
    __weak typeof(self) weakSelf = self;
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:self.sendIntervalSeconds
                                                     repeats:YES
                                                       block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf _sendPendingMetrics];
        } else {
            [timer invalidate];
        }
    }];
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
        }
    }
    
    if (events.count == 0) {
        return;
    }
    
    // Send via bulk API
    [self.bulkApi sendToEndpoint:self.endpoint items:events completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            // Delete successfully sent metrics
            dispatch_async(self.metricsQueue, ^{
                for (CLXMetricsEvent *metric in metrics) {
                    [self.metricsDao deleteById:metric.eventId];
                }
            });
        } else {
            [self.logger warn:[NSString stringWithFormat:@"Failed to send metrics: %@", error.localizedDescription ?: @"Unknown error"]];
        }
    }];
}

- (nullable CLXEventAM *)_buildEventFromMetric:(CLXMetricsEvent *)metric {
    if (!metric) {
        [self.logger error:@"Cannot build event - metric is nil"];
        return nil;
    }
    
    if (!self.accountId || self.accountId.length == 0) {
        [self.logger error:@"Cannot build event - accountId is nil or empty"];
        return nil;
    }
    
    // Build payload matching Android format: basePayload;metricName;counter/totalLatency
    NSString *metricDetail = [NSString stringWithFormat:@"%ld/%ld", (long)metric.counter, (long)metric.totalLatency];
    NSString *payload = [NSString stringWithFormat:@"%@;%@;%@", 
                        self.basePayload ?: @"", 
                        metric.metricName ?: @"", 
                        metricDetail];
    
    // Replace {eventId} placeholder with actual event ID (handle nil auctionId)
    NSString *auctionId = metric.auctionId ?: @"unknown";
    payload = [payload stringByReplacingOccurrencesOfString:@"{eventId}" withString:auctionId];
    
    // Generate XOR encryption data matching Android exactly
    NSData *secret = [CLXXorEncryption generateXorSecret:self.accountId];
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64:self.accountId];
    NSString *impressionId = [CLXXorEncryption encrypt:payload secret:secret];
    
    return [[CLXEventAM alloc] initWithImpression:impressionId
                                       campaignId:campaignId
                                       eventValue:@"N/A"
                                        eventName:@"SDK_METRICS"
                                             type:@"SDK_METRICS"];
}

#pragma mark - Debug Methods

#ifdef DEBUG
- (void)debugPrintStatus {
    [CLXMetricsDebugger debugMetricsTracker:self];
    [CLXMetricsDebugger debugConfiguration:self.metricsConfig];
    [CLXMetricsDebugger printAllMetrics:self.metricsDao];
    
    // Additional debug info specific to this tracker instance
    [self.logger info:@"🔍 TRACKER INSTANCE DEBUG"];
    [self.logger info:@"========================="];
    [self.logger info:[NSString stringWithFormat:@"Session ID: %@", self.sessionId ?: @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"👤 Account ID: %@", self.accountId ?: @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"Base Payload Length: %lu chars", (unsigned long)(self.basePayload ? self.basePayload.length : 0)]];
    [self.logger info:[NSString stringWithFormat:@"⏰ Send Timer: %@", self.sendTimer ? @"Active" : @"Inactive"]];
    
    // Performance report
    NSString *perfReport = [CLXMetricsDebugger generatePerformanceReport:self.metricsDao];
    [self.logger info:perfReport];
    
    // Encryption test
    if (self.accountId && self.accountId.length > 0) {
        NSString *encryptionTest = [CLXMetricsDebugger testEncryption:self.accountId];
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
