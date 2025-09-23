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
            [self.logger info:@"⚠️ [MetricsTrackerImpl] Metrics configuration is nil, skipping metrics tracking"];
            return;
        }
        
        // Use impressionTrackerURL for metrics like Android uses trackingEndpointUrl
        NSString *metricsURL = config.impressionTrackerURL ?: config.metricsEndpointURL;
        if (metricsURL && metricsURL.length > 0) {
            self.endpoint = [NSString stringWithFormat:@"%@/bulk?debug=true", metricsURL];
            [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Using endpoint: %@ (from %@)", 
                               self.endpoint, config.impressionTrackerURL ? @"impressionTrackerURL" : @"metricsEndpointURL"]];
        } else {
            self.endpoint = nil;
            [self.logger info:@"⚠️ [MetricsTrackerImpl] No impression tracker or metrics endpoint URL provided, metrics sending disabled"];
        }
        self.sendIntervalSeconds = self.metricsConfig.sendIntervalSeconds ?: 60;
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Starting metrics tracker with cycle duration: %ld seconds", 
                           (long)self.sendIntervalSeconds]];
        
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
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Basic data set - sessionId: %@, accountId: %@", 
                           sessionId ? @"YES" : @"NO", accountId ? @"YES" : @"NO"]];
    });
}

- (void)trackMethodCall:(NSString *)methodType {
    if (![CLXMetricsType isMethodCallType:methodType]) {
        [self.logger error:[NSString stringWithFormat:@"❌ [MetricsTrackerImpl] Invalid method type: %@", methodType]];
        return;
    }
    
    dispatch_async(self.metricsQueue, ^{
        // Check if SDK API calls are enabled
        BOOL isMethodCallMetricsEnabled = [self.metricsConfig isSdkApiCallsEnabled];
        if (!isMethodCallMetricsEnabled) {
            [self.logger info:[NSString stringWithFormat:@"⚠️ [MetricsTrackerImpl] SDK API call metrics tracking is disabled for %@", methodType]];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Tracking SDK API call: %@", methodType]];
        [self _trackMetric:methodType latency:0];
    });
}

- (void)trackNetworkCall:(NSString *)networkType latency:(NSInteger)latencyMs {
    if (![CLXMetricsType isNetworkCallType:networkType]) {
        [self.logger error:[NSString stringWithFormat:@"❌ [MetricsTrackerImpl] Invalid network type: %@", networkType]];
        return;
    }
    
    dispatch_async(self.metricsQueue, ^{
        BOOL isNetworkCallMetricsEnabled = [self.metricsConfig isNetworkCallsEnabled];
        BOOL isCallMetricsEnabled = NO;
        
        if ([networkType isEqualToString:CLXMetricsTypeNetworkSdkInit]) {
            isCallMetricsEnabled = [self.metricsConfig isInitSdkNetworkCallsEnabled];
        } else if ([networkType isEqualToString:CLXMetricsTypeNetworkGeoApi]) {
            isCallMetricsEnabled = [self.metricsConfig isGeoNetworkCallsEnabled];
        } else if ([networkType isEqualToString:CLXMetricsTypeNetworkBidRequest]) {
            isCallMetricsEnabled = [self.metricsConfig isBidRequestNetworkCallsEnabled];
        }
        
        if (isNetworkCallMetricsEnabled && isCallMetricsEnabled) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Tracking network request: %@ with latency: %ld ms", 
                               networkType, (long)latencyMs]];
            [self _trackMetric:networkType latency:latencyMs];
        } else {
            [self.logger info:[NSString stringWithFormat:@"⚠️ [MetricsTrackerImpl] Network call metrics tracking is disabled for %@", networkType]];
        }
    });
}

- (void)trySendingPendingMetrics {
    dispatch_async(self.metricsQueue, ^{
        [self.logger debug:@"📊 [MetricsTrackerImpl] Attempting to send pending metrics"];
        [self _sendPendingMetrics];
    });
}

- (void)stop {
    if (self.metricsQueue) {
        dispatch_async(self.metricsQueue, ^{
            [self _stopPeriodicSending];
            [self.logger debug:@"📊 [MetricsTrackerImpl] Metrics tracker stopped"];
        });
    } else {
        // Fallback for cases where queue is not available
        [self _stopPeriodicSending];
        [self.logger debug:@"📊 [MetricsTrackerImpl] Metrics tracker stopped (synchronous fallback)"];
    }
}

#pragma mark - Private Methods

- (void)_trackMetric:(NSString *)metricType latency:(NSInteger)latency {
    [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Tracking metric: %@ with latency: %ld ms", 
                       metricType, (long)latency]];
    
    // Get existing metric for aggregation (matching Android logic)
    CLXMetricsEvent *existingMetric = [self.metricsDao getAllByMetric:metricType];
    [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Existing metric for %@: %@", 
                       metricType, existingMetric ? @"YES" : @"NO"]];
    
    CLXMetricsEvent *updatedMetric;
    if (!existingMetric) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Creating new metric for %@", metricType]];
        updatedMetric = [[CLXMetricsEvent alloc] initWithEventId:[[NSUUID UUID] UUIDString]
                                                      metricName:metricType
                                                         counter:1
                                                    totalLatency:latency
                                                       sessionId:self.sessionId
                                                       auctionId:[[NSUUID UUID] UUIDString]];
    } else {
        [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Updating existing metric for %@", metricType]];
        updatedMetric = [[CLXMetricsEvent alloc] initWithEventId:existingMetric.eventId
                                                      metricName:existingMetric.metricName
                                                         counter:existingMetric.counter + 1
                                                    totalLatency:existingMetric.totalLatency + latency
                                                       sessionId:existingMetric.sessionId
                                                       auctionId:existingMetric.auctionId];
    }
    
    [self.metricsDao insert:updatedMetric];
}

- (void)_startPeriodicSending {
    [self _stopPeriodicSending]; // Stop any existing timer
    
    if (self.sendIntervalSeconds <= 0) {
        [self.logger info:@"⚠️ [MetricsTrackerImpl] Invalid send interval, periodic sending disabled"];
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
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Started periodic sending every %ld seconds", 
                       (long)self.sendIntervalSeconds]];
}

- (void)_stopPeriodicSending {
    if (self.sendTimer) {
        if ([self.sendTimer isValid]) {
            [self.sendTimer invalidate];
        }
        self.sendTimer = nil;
        [self.logger debug:@"📊 [MetricsTrackerImpl] Stopped periodic sending"];
    }
}

- (void)_sendPendingMetrics {
    NSArray<CLXMetricsEvent *> *metrics = [self.metricsDao getAll];
    [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Found %lu pending metrics", 
                       (unsigned long)metrics.count]];
    
    if (metrics.count == 0 || !self.endpoint || self.endpoint.length == 0) {
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
        [self.logger debug:@"📊 [MetricsTrackerImpl] No valid events to send"];
        return;
    }
    
    // Send via bulk API
    [self.bulkApi sendToEndpoint:self.endpoint items:events completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self.logger debug:[NSString stringWithFormat:@"✅ [MetricsTrackerImpl] Successfully sent %lu metrics", (unsigned long)events.count]];
            
            // Delete successfully sent metrics
            dispatch_async(self.metricsQueue, ^{
                for (CLXMetricsEvent *metric in metrics) {
                    [self.metricsDao deleteById:metric.eventId];
                }
                [self.logger debug:[NSString stringWithFormat:@"🗑️ [MetricsTrackerImpl] Cleaned up %lu sent metrics", (unsigned long)metrics.count]];
            });
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [MetricsTrackerImpl] Failed to send metrics: %@", error.localizedDescription ?: @"Unknown error"]];
        }
    }];
}

- (nullable CLXEventAM *)_buildEventFromMetric:(CLXMetricsEvent *)metric {
    if (!metric) {
        [self.logger error:@"❌ [MetricsTrackerImpl] Cannot build event - metric is nil"];
        return nil;
    }
    
    if (!self.accountId || self.accountId.length == 0) {
        [self.logger error:@"❌ [MetricsTrackerImpl] Cannot build event - accountId is nil or empty"];
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
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [MetricsTrackerImpl] Building event for metric: %@ with payload: %@", 
                       metric.metricName ?: @"unknown", payload]];
    
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
    [self.logger info:[NSString stringWithFormat:@"📱 Session ID: %@", self.sessionId ?: @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"👤 Account ID: %@", self.accountId ?: @"(nil)"]];
    [self.logger info:[NSString stringWithFormat:@"📦 Base Payload Length: %lu chars", (unsigned long)(self.basePayload ? self.basePayload.length : 0)]];
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

@end
