//
//  MetricsNetworkService.m
//  CloudXCore
//
//  Created by Migration Tool.
//

#import <CloudXCore/CLXMetricsNetworkService.h>
#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXPerformanceMetricModel.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

@interface CLXMetricsNetworkService ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetricsNetworkServiceRequestSessionMetric

- (instancetype)initWithMetric:(CLXSessionMetricSpend *)metric {
    self = [super init];
    if (self) {
        _placementID = [metric.placementID copy];
        _type = [CLXSessionMetricTypeRawValue(metric.type) copy];
        _value = @(metric.value);
        _timestamp = [metric.timestamp copy];
        _meta = nil;
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type meta:(NSDictionary<NSString *, NSNumber *> *)meta {
    self = [super init];
    if (self) {
        _meta = [meta copy];
        _type = [type copy];
        _timestamp = nil;
        _placementID = nil;
        _value = nil;
    }
    return self;
}

@end

@implementation CLXMetricsNetworkServiceRequestSession

- (instancetype)initWithID:(NSString *)ID
                  duration:(NSInteger)duration
                   metrics:(NSArray<CLXMetricsNetworkServiceRequestSessionMetric *> *)metrics {
    self = [super init];
    if (self) {
        _ID = [ID copy];
        _duration = duration;
        _metrics = [metrics copy];
    }
    return self;
}

@end

@implementation CLXMetricsNetworkServiceRequest

- (instancetype)initWithSession:(CLXMetricsNetworkServiceRequestSession *)session {
    self = [super init];
    if (self) {
        _session = session;
    }
    return self;
}

@end

@implementation CLXMetricsNetworkService

- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession {
    self = [super initWithBaseURL:baseURL urlSession:urlSession];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"MetricsNetworkService"];
    }
    return self;
}

- (void)trackEndSessionWithSession:(CLXAppSessionModel *)session {
    [self trackEndSessionWithSession:session completion:^(BOOL success, NSError * _Nullable error) {
        // Default completion handler
    }];
}

- (void)trackEndSessionWithSession:(CLXAppSessionModel *)session
                       completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    // Validate required parameters
    if (!session.id || !session.appKey) {
        NSError *error = [NSError errorWithDomain:@"MetricsNetworkService"
                                           code:MetricsNetworkErrorInvalidRequest
                                       userInfo:@{NSLocalizedDescriptionKey: @"Invalid request: missing session ID or app key"}];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    // Convert session metrics to request metrics
    NSMutableArray<CLXMetricsNetworkServiceRequestSessionMetric *> *metrics = [NSMutableArray array];
    
    // Convert regular metrics
    if (session.metrics) {
        for (CLXSessionMetricModel *metricModel in session.metrics.allObjects) {
            CLXSessionMetricSpend *metricSpend = [[CLXSessionMetricSpend alloc] initWithMetricModel:metricModel];
            if (metricSpend) {
                CLXMetricsNetworkServiceRequestSessionMetric *metric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithMetric:metricSpend];
                [metrics addObject:metric];
            }
        }
    }
    
    // Convert performance metrics
    if (session.performanceMetrics) {
        NSMutableDictionary<NSString *, NSNumber *> *fillRateMeta = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSNumber *> *ctrMeta = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSNumber *> *bidRequestLatencyMeta = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSNumber *> *adLoadLatencyMeta = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSNumber *> *clickCountMeta = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSNumber *> *failToLoadAdCountMeta = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSNumber *> *closeLatencyMeta = [NSMutableDictionary dictionary];
        
        for (CLXPerformanceMetricModel *metric in session.performanceMetrics.allObjects) {
            NSString *placementID = metric.placementID;
            if (!placementID) continue;
            
            // Calculate fill rate
            double fillRate = 0.0;
            if (metric.bidResponseCount != 0) {
                fillRate = (double)metric.impressionCount / (double)metric.bidResponseCount * 100.0;
            }
            fillRateMeta[placementID] = @(fillRate);
            [self.logger debug:[NSString stringWithFormat:@"Fillrate for %@: %f", placementID, fillRate]];
            
            // Calculate CTR
            double ctr = 0.0;
            if (metric.impressionCount != 0) {
                ctr = (double)metric.clickCount / (double)metric.impressionCount * 100.0;
            }
            ctrMeta[placementID] = @(ctr);
            [self.logger debug:[NSString stringWithFormat:@"CTR for %@: %f", placementID, ctr]];
            
            // Calculate bid request latency
            double bidRequestLatency = 0.0;
            if (metric.bidResponseCount != 0) {
                bidRequestLatency = metric.bidRequestLatency / (double)metric.bidResponseCount;
            }
            bidRequestLatencyMeta[placementID] = @(bidRequestLatency);
            [self.logger debug:[NSString stringWithFormat:@"Bid request latency for %@: %f", placementID, bidRequestLatency]];
            
            // Calculate ad load latency
            double adLoadLatency = 0.0;
            if (metric.adLoadCount != 0) {
                adLoadLatency = metric.adLoadLatency / (double)metric.adLoadCount;
            }
            adLoadLatencyMeta[placementID] = @(adLoadLatency);
            [self.logger debug:[NSString stringWithFormat:@"Ad load latency for %@: %f", placementID, adLoadLatency]];
            
            // Click count
            clickCountMeta[placementID] = @(metric.clickCount);
            [self.logger debug:[NSString stringWithFormat:@"Click count for %@: %ld", placementID, (long)metric.clickCount]];
            
            // Fail to load ad count
            failToLoadAdCountMeta[placementID] = @(metric.failToLoadAdCount);
            [self.logger debug:[NSString stringWithFormat:@"Fail to load ad count for %@: %ld", placementID, (long)metric.failToLoadAdCount]];
            
            // Close latency
            double closeLatency = 0.0;
            if (metric.closeCount != 0) {
                closeLatency = metric.closeLatency / (double)metric.closeCount;
            }
            closeLatencyMeta[placementID] = @(closeLatency);
            [self.logger debug:[NSString stringWithFormat:@"Close latency for %@: %f", placementID, closeLatency]];
        }
        
        // Create performance metrics
        CLXMetricsNetworkServiceRequestSessionMetric *fillRateMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeFillRate) meta:fillRateMeta];
        CLXMetricsNetworkServiceRequestSessionMetric *ctrMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeCTR) meta:ctrMeta];
        CLXMetricsNetworkServiceRequestSessionMetric *bidRequestLatencyMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeBidRequestLatency) meta:bidRequestLatencyMeta];
        CLXMetricsNetworkServiceRequestSessionMetric *adLoadLatencyMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeAdLoadLatency) meta:adLoadLatencyMeta];
        CLXMetricsNetworkServiceRequestSessionMetric *clickCountMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeClickCount) meta:clickCountMeta];
        CLXMetricsNetworkServiceRequestSessionMetric *failToLoadAdCountMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeAdLoadFailCount) meta:failToLoadAdCountMeta];
        CLXMetricsNetworkServiceRequestSessionMetric *closeLatencyMetric = [[CLXMetricsNetworkServiceRequestSessionMetric alloc] initWithType:CLXSessionMetricTypeRawValue(CLXSessionMetricTypeCloseLatency) meta:closeLatencyMeta];
        
        [metrics addObjectsFromArray:@[fillRateMetric, ctrMetric, bidRequestLatencyMetric, adLoadLatencyMetric, clickCountMetric, failToLoadAdCountMetric, closeLatencyMetric]];
    }
    
    // Create session
    CLXMetricsNetworkServiceRequestSession *requestSession = [[CLXMetricsNetworkServiceRequestSession alloc] initWithID:session.id
                                                                                                         duration:(NSInteger)session.duration
                                                                                                          metrics:metrics];
    
    // Create request
    CLXMetricsNetworkServiceRequest *request = [[CLXMetricsNetworkServiceRequest alloc] initWithSession:requestSession];
    
    // Convert to JSON
    NSDictionary *requestJSON = [self convertRequestToJSON:request];
    
    // Log request for debugging
    if (requestJSON) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestJSON options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.logger debug:[NSString stringWithFormat:@"Metrics request JSON: %@", jsonString]];
    }
    
    // Create headers
    NSDictionary *headers = @{@"Authorization": [NSString stringWithFormat:@"Bearer %@", session.appKey]};
    
    // Serialize request body
    NSData *requestBody = nil;
    if (requestJSON) {
        requestBody = [NSJSONSerialization dataWithJSONObject:requestJSON options:0 error:nil];
    }
    
    // Execute request using BaseNetworkService method
    [self executeRequestWithEndpoint:@""
                        urlParameters:@{}
                           requestBody:requestBody
                               headers:headers
                            maxRetries:3
                                delay:1.0
                           completion:^(id _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Failed to track end session: %@", error.localizedDescription]];
            if (completion) {
                completion(NO, error);
            }
        } else {
            [self.logger debug:@"Successfully tracked end session"];
            if (completion) {
                completion(YES, nil);
            }
        }
    }];
}

- (NSDictionary *)convertRequestToJSON:(CLXMetricsNetworkServiceRequest *)request {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    if (request.session) {
        NSMutableDictionary *sessionDict = [NSMutableDictionary dictionary];
        sessionDict[@"ID"] = request.session.ID;
        sessionDict[@"duration"] = @(request.session.duration);
        
        NSMutableArray *metricsArray = [NSMutableArray array];
        for (CLXMetricsNetworkServiceRequestSessionMetric *metric in request.session.metrics) {
            NSMutableDictionary *metricDict = [NSMutableDictionary dictionary];
            
            if (metric.placementID) {
                metricDict[@"placementID"] = metric.placementID;
            }
            metricDict[@"type"] = metric.type;
            
            if (metric.value) {
                metricDict[@"value"] = metric.value;
            }
            
            if (metric.timestamp) {
                // Convert date to Unix timestamp (seconds since 1970)
                NSTimeInterval timestamp = [metric.timestamp timeIntervalSince1970];
                metricDict[@"timestamp"] = @((NSUInteger)timestamp);
            }
            
            if (metric.meta) {
                metricDict[@"by_placement_id"] = metric.meta;
            }
            
            [metricsArray addObject:metricDict];
        }
        
        sessionDict[@"metrics"] = metricsArray;
        json[@"session"] = sessionDict;
    }
    
    return [json copy];
}

@end 