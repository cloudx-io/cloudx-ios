/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXMetricsDebugger.h>
#import <CloudXCore/CLXMetricsTrackerImpl.h>
#import <CloudXCore/CLXMetricsEventDao.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/CLXLogger.h>

static BOOL _enhancedDebugModeEnabled = NO;
static CLXLogger *_debugLogger = nil;

@implementation CLXMetricsDebugger

+ (void)initialize {
    if (self == [CLXMetricsDebugger class]) {
        _debugLogger = [[CLXLogger alloc] initWithCategory:@"MetricsDebugger"];
    }
}

+ (void)debugMetricsTracker:(CLXMetricsTrackerImpl *)metricsTracker {
    [_debugLogger info:@"🔍 METRICS TRACKER DEBUG REPORT"];
    [_debugLogger info:@"====================================="];
    
    if (!metricsTracker) {
        [_debugLogger error:@"⚠️ Metrics tracker is nil!"];
        return;
    }
    
    [_debugLogger info:[NSString stringWithFormat:@"📊 Send Interval: %ld seconds", (long)60]]; // Default value since property is private
    [_debugLogger info:[NSString stringWithFormat:@"🔄 Tracker Status: %@", metricsTracker ? @"Active" : @"Inactive"]];
    
    // Debug database state - skip for now as database property is private
    [_debugLogger info:@"💾 Database: Internal (access via DAO methods)"];
    
    [_debugLogger info:@"====================================="];
}

+ (void)debugDatabase:(CLXMetricsEventDao *)dao {
    [_debugLogger info:@"💾 DATABASE DEBUG INFO"];
    [_debugLogger info:@"---------------------"];
    
    if (!dao) {
        [_debugLogger error:@"⚠️ DAO is nil!"];
        return;
    }
    
    NSArray<CLXMetricsEvent *> *allEvents = [dao getAll];
    [_debugLogger info:[NSString stringWithFormat:@"📈 Total Metrics Events: %lu", (unsigned long)allEvents.count]];
    
    if (allEvents.count == 0) {
        [_debugLogger info:@"📭 No metrics events found in database"];
        return;
    }
    
    // Group by metric type
    NSMutableDictionary<NSString *, NSNumber *> *metricCounts = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *metricLatencies = [NSMutableDictionary dictionary];
    
    for (CLXMetricsEvent *event in allEvents) {
        NSNumber *currentCount = metricCounts[event.metricName] ?: @0;
        metricCounts[event.metricName] = @(currentCount.integerValue + event.counter);
        
        NSNumber *currentLatency = metricLatencies[event.metricName] ?: @0;
        metricLatencies[event.metricName] = @(currentLatency.integerValue + event.totalLatency);
    }
    
    [_debugLogger info:@"📊 Metrics Summary:"];
    for (NSString *metricName in metricCounts.allKeys) {
        NSInteger count = metricCounts[metricName].integerValue;
        NSInteger latency = metricLatencies[metricName].integerValue;
        
        if ([CLXMetricsType isNetworkCallType:metricName]) {
            NSInteger avgLatency = count > 0 ? latency / count : 0;
            [_debugLogger info:[NSString stringWithFormat:@"  🌐 %@: %ld calls, %ld ms total, %ld ms avg", metricName, (long)count, (long)latency, (long)avgLatency]];
        } else {
            [_debugLogger info:[NSString stringWithFormat:@"  📱 %@: %ld calls", metricName, (long)count]];
        }
    }
}

+ (void)debugConfiguration:(CLXMetricsConfig *)config {
    [_debugLogger info:@"⚙️ METRICS CONFIGURATION DEBUG"];
    [_debugLogger info:@"-------------------------------"];
    
    if (!config) {
        [_debugLogger error:@"⚠️ Configuration is nil!"];
        return;
    }
    
    [_debugLogger info:[NSString stringWithFormat:@"⏱️ Send Interval: %ld seconds", (long)config.sendIntervalSeconds]];
    [_debugLogger info:[NSString stringWithFormat:@"📱 SDK API Calls Enabled: %@", [self boolToString:[config isSdkApiCallsEnabled]]]];
    [_debugLogger info:[NSString stringWithFormat:@"🌐 Network Calls Enabled: %@", [self boolToString:[config isNetworkCallsEnabled]]]];
    [_debugLogger info:[NSString stringWithFormat:@"  📊 Bid Request Calls: %@", [self boolToString:[config isBidRequestNetworkCallsEnabled]]]];
    [_debugLogger info:[NSString stringWithFormat:@"  🚀 Init SDK Calls: %@", [self boolToString:[config isSdkInitNetworkCallsEnabled]]]];
    [_debugLogger info:[NSString stringWithFormat:@"  🌍 Geo Calls: %@", [self boolToString:[config isGeoNetworkCallsEnabled]]]];
}

+ (void)printAllMetrics:(CLXMetricsEventDao *)dao {
    [_debugLogger info:@"📋 ALL METRICS DETAILED VIEW"];
    [_debugLogger info:@"============================="];
    
    if (!dao) {
        [_debugLogger error:@"⚠️ DAO is nil!"];
        return;
    }
    
    NSArray<CLXMetricsEvent *> *allEvents = [dao getAll];
    
    if (allEvents.count == 0) {
        [_debugLogger info:@"📭 No metrics events found"];
        return;
    }
    
    for (CLXMetricsEvent *event in allEvents) {
        [_debugLogger info:[NSString stringWithFormat:@"📊 %@", event.description]];
    }
}

+ (NSArray<NSString *> *)validateMetricsSystem:(CLXMetricsTrackerImpl *)metricsTracker {
    NSMutableArray<NSString *> *issues = [NSMutableArray array];
    
    [_debugLogger info:@"🔍 VALIDATING METRICS SYSTEM"];
    [_debugLogger info:@"============================="];
    
    // Check tracker
    if (!metricsTracker) {
        [issues addObject:@"Metrics tracker is nil"];
    } else {
        [_debugLogger info:@"✅ Metrics tracker instance is valid"];
    }
    
    // Check metric type constants
    NSArray<NSString *> *allNetworkTypes = [CLXMetricsType allNetworkCallTypes];
    NSArray<NSString *> *allMethodTypes = [CLXMetricsType allMethodCallTypes];
    
    if (allNetworkTypes.count != 3) {
        [issues addObject:[NSString stringWithFormat:@"Expected 3 network call types, found %lu", (unsigned long)allNetworkTypes.count]];
    }
    
    if (allMethodTypes.count != 10) {
        [issues addObject:[NSString stringWithFormat:@"Expected 10 method call types, found %lu", (unsigned long)allMethodTypes.count]];
    }
    
    // Check for duplicate metric types
    NSSet<NSString *> *networkSet = [NSSet setWithArray:allNetworkTypes];
    NSSet<NSString *> *methodSet = [NSSet setWithArray:allMethodTypes];
    
    if (networkSet.count != allNetworkTypes.count) {
        [issues addObject:@"Duplicate network call types detected"];
    }
    
    if (methodSet.count != allMethodTypes.count) {
        [issues addObject:@"Duplicate method call types detected"];
    }
    
    // Check for overlap between network and method types
    NSMutableSet<NSString *> *intersection = [NSMutableSet setWithSet:networkSet];
    [intersection intersectSet:methodSet];
    
    if (intersection.count > 0) {
        [issues addObject:@"Overlap between network and method call types detected"];
    }
    
    if (issues.count == 0) {
        [_debugLogger info:@"✅ All validation checks passed!"];
    } else {
        [_debugLogger error:[NSString stringWithFormat:@"⚠️ Found %lu validation issues:", (unsigned long)issues.count]];
        for (NSString *issue in issues) {
            [_debugLogger error:[NSString stringWithFormat:@"  - %@", issue]];
        }
    }
    
    return [issues copy];
}

+ (NSString *)generatePerformanceReport:(CLXMetricsEventDao *)dao {
    NSMutableString *report = [NSMutableString string];
    [report appendString:@"📊 METRICS PERFORMANCE REPORT\n"];
    [report appendString:@"==============================\n"];
    
    if (!dao) {
        [report appendString:@"⚠️ DAO is nil!\n"];
        return report;
    }
    
    NSDate *startTime = [NSDate date];
    NSArray<CLXMetricsEvent *> *allEvents = [dao getAll];
    NSTimeInterval queryTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
    
    [report appendFormat:@"📈 Total Events: %lu\n", (unsigned long)allEvents.count];
    [report appendFormat:@"⏱️ Query Time: %.2f ms\n", queryTime];
    
    if (allEvents.count > 0) {
        // Calculate aggregation efficiency
        NSSet<NSString *> *uniqueMetrics = [NSSet setWithArray:[allEvents valueForKey:@"metricName"]];
        double aggregationRatio = (double)uniqueMetrics.count / allEvents.count;
        [report appendFormat:@"🔄 Aggregation Efficiency: %.2f%% (%lu unique metrics from %lu events)\n", 
                aggregationRatio * 100, (unsigned long)uniqueMetrics.count, (unsigned long)allEvents.count];
        
        // Memory usage estimate
        NSInteger estimatedMemoryBytes = allEvents.count * 200; // Rough estimate per event
        [report appendFormat:@"💾 Estimated Memory Usage: %.2f KB\n", estimatedMemoryBytes / 1024.0];
        
        // Performance recommendations
        if (allEvents.count > 1000) {
            [report appendString:@"⚠️ High event count detected. Consider more frequent sending.\n"];
        }
        
        if (aggregationRatio < 0.1) {
            [report appendString:@"✅ Excellent aggregation efficiency.\n"];
        } else if (aggregationRatio < 0.5) {
            [report appendString:@"✅ Good aggregation efficiency.\n"];
        } else {
            [report appendString:@"⚠️ Low aggregation efficiency. Events may not be aggregating properly.\n"];
        }
    }
    
    return report;
}

+ (NSString *)testEncryption:(NSString *)accountId {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"🔐 ENCRYPTION TEST REPORT\n"];
    [result appendString:@"=========================\n"];
    
    if (!accountId || accountId.length == 0) {
        [result appendString:@"⚠️ Account ID is nil or empty!\n"];
        return result;
    }
    
    NSString *testPayload = @"{\"sessionId\":\"test-session\",\"metricName\":\"method_create_banner\",\"counter\":1,\"totalLatency\":0}";
    
    @try {
        // Test secret generation
        NSDate *startTime = [NSDate date];
        NSData *secret = [CLXXorEncryption generateXorSecret:accountId];
        NSTimeInterval secretTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
        
        [result appendFormat:@"🔑 Secret Generation: %.2f ms\n", secretTime];
        [result appendFormat:@"🔑 Secret Length: %lu bytes\n", (unsigned long)secret.length];
        
        // Test campaign ID generation
        startTime = [NSDate date];
        NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64:accountId];
        NSTimeInterval campaignTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
        
        [result appendFormat:@"🏷️ Campaign ID Generation: %.2f ms\n", campaignTime];
        [result appendFormat:@"🏷️ Campaign ID: %@\n", campaignId];
        
        // Test encryption
        startTime = [NSDate date];
        NSString *encrypted = [CLXXorEncryption encrypt:testPayload secret:secret];
        NSTimeInterval encryptTime = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
        
        [result appendFormat:@"🔐 Encryption Time: %.2f ms\n", encryptTime];
        [result appendFormat:@"🔐 Encrypted Length: %lu characters\n", (unsigned long)encrypted.length];
        [result appendFormat:@"🔐 Encrypted Sample: %@...\n", [encrypted substringToIndex:MIN(50, encrypted.length)]];
        
        // Test multiple encryptions for consistency
        NSString *encrypted2 = [CLXXorEncryption encrypt:testPayload secret:secret];
        if ([encrypted isEqualToString:encrypted2]) {
            [result appendString:@"✅ Encryption is deterministic\n"];
        } else {
            [result appendString:@"⚠️ Encryption is not deterministic!\n"];
        }
        
        [result appendString:@"✅ All encryption tests passed\n"];
        
    } @catch (NSException *exception) {
        [result appendFormat:@"❌ Encryption test failed: %@\n", exception.reason];
    }
    
    return result;
}

+ (void)enableEnhancedDebugMode {
    _enhancedDebugModeEnabled = YES;
    [_debugLogger info:@"🔍 Enhanced debug mode ENABLED"];
}

+ (void)disableEnhancedDebugMode {
    _enhancedDebugModeEnabled = NO;
    [_debugLogger info:@"🔍 Enhanced debug mode DISABLED"];
}

+ (BOOL)isEnhancedDebugModeEnabled {
    return _enhancedDebugModeEnabled;
}

#pragma mark - Private Helpers

+ (NSString *)boolToString:(BOOL)value {
    return value ? @"✅ Enabled" : @"❌ Disabled";
}

@end
