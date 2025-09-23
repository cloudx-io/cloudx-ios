# CloudX iOS Metrics Architecture

## Overview

The CloudX iOS SDK now features a comprehensive metrics tracking system that provides full parity with the Android implementation. This system tracks SDK usage patterns, method calls, and network performance to provide insights into SDK behavior and performance.

## Architecture Components

### Core Components

#### 1. CLXMetricsTrackerImpl
- **Purpose**: Main metrics tracking implementation
- **Location**: `AdReporting/MetricsTracker/CLXMetricsTrackerImpl.h/m`
- **Responsibilities**:
  - Track method calls and network calls
  - Aggregate metrics by type
  - Persist metrics to SQLite database
  - Send metrics periodically via bulk API
  - Apply XOR encryption to metrics payloads
  - Manage metrics lifecycle (start/stop)

#### 2. CLXMetricsEvent
- **Purpose**: Data model for individual metrics events
- **Location**: `AdReporting/MetricsTracker/CLXMetricsEvent.h/m`
- **Properties**:
  - `eventId`: Unique identifier for the event
  - `metricName`: Type of metric (e.g., "method_create_banner")
  - `counter`: Number of times this metric occurred
  - `totalLatency`: Total latency for network calls (0 for method calls)
  - `sessionId`: Current session identifier
  - `auctionId`: Auction identifier (if applicable)

#### 3. CLXMetricsEventDao
- **Purpose**: Data Access Object for metrics persistence
- **Location**: `AdReporting/MetricsTracker/CLXMetricsEventDao.h/m`
- **Methods**:
  - `insert:` - Insert or update a metrics event
  - `getAllByMetric:` - Retrieve event by metric name
  - `getAll` - Retrieve all stored events
  - `deleteById:` - Delete event by ID

#### 4. CLXMetricsType
- **Purpose**: Constants for all metric types
- **Location**: `AdReporting/MetricsTracker/CLXMetricsType.h/m`
- **Categories**:
  - **Network Calls**: `network_call_sdk_init_req`, `network_call_geo_req`, `network_call_bid_req`
  - **Method Calls**: `method_sdk_init`, `method_create_banner`, `method_create_interstitial`, etc.

#### 5. CLXMetricsConfig
- **Purpose**: Configuration for metrics behavior
- **Location**: `AdReporting/MetricsTracker/CLXMetricsConfig.h/m`
- **Properties**:
  - `sendIntervalSeconds`: How often to send metrics (default: 60s)
  - `sdkApiCallsEnabled`: Enable/disable method call tracking
  - `networkCallsEnabled`: Enable/disable network call tracking
  - Fine-grained network call controls (bid, init, geo)

### Supporting Components

#### 6. CLXEventAM
- **Purpose**: Event model for bulk API submission
- **Location**: `AdReporting/MetricsTracker/CLXEventAM.h/m`
- **Usage**: Converts metrics to encrypted format for transmission

#### 7. CLXEventTrackerBulkApi
- **Purpose**: Network client for bulk metrics submission
- **Location**: `AdReporting/MetricsTracker/CLXEventTrackerBulkApi.h/m`
- **Features**: HTTP POST with JSON payload, timeout handling, error reporting

## Data Flow

### 1. Metric Collection
```
SDK Method Call → CLXMetricsTrackerImpl.trackMethodCall() → Aggregate → SQLite
Network Call → CLXMetricsTrackerImpl.trackNetworkCall() → Aggregate → SQLite
```

### 2. Metric Aggregation
- Method calls: Increment counter only
- Network calls: Increment counter + add to totalLatency
- Events are aggregated by metric name within the same session

### 3. Periodic Sending
```
NSTimer (60s) → Fetch all metrics → Build CLXEventAM → XOR Encrypt → HTTP POST → Delete on success
```

### 4. Encryption Process
```
Metric Data → JSON Payload → XOR Encryption → Base64 Encode → CLXEventAM.impression
```

## Integration Points

### 1. CloudXCoreAPI Integration
All public SDK methods now include metrics tracking:

```objective-c
- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(BOOL, NSError *))completion {
    // Track method call
    id<CLXMetricsTrackerProtocol> metricsTracker = [[CLXDIContainer shared] resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];
    [metricsTracker trackMethodCall:CLXMetricsTypeMethodSdkInit];
    
    // ... existing implementation
}
```

### 2. Network Service Integration
All network services track latency:

```objective-c
NSDate *startTime = [NSDate date];
[self executeRequest:request completion:^(id response, NSError *error, BOOL killSwitch) {
    NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:startTime] * 1000;
    [metricsTracker trackNetworkCall:CLXMetricsTypeNetworkBidRequest latency:(NSInteger)latency];
    // ... handle response
}];
```

### 3. Dependency Injection
Metrics components are registered in `CloudXCoreAPI.m`:

```objective-c
[container registerType:[CLXMetricsTrackerImpl class] instance:[[CLXMetricsTrackerImpl alloc] init]];
```

## Configuration

### Server-Side Configuration
Metrics behavior is controlled via `CLXSDKConfig.metricsConfig`:

```json
{
  "metricsConfig": {
    "send_interval_seconds": 120,
    "sdk_api_calls.enabled": true,
    "network_calls.enabled": true,
    "network_calls.bid_req.enabled": true,
    "network_calls.init_sdk_req.enabled": false,
    "network_calls.geo_req.enabled": true
  }
}
```

### Runtime Configuration
```objective-c
CLXMetricsConfig *config = [[CLXMetricsConfig alloc] init];
config.sendIntervalSeconds = 120;
config.sdkApiCallsEnabled = @YES;
config.networkCallsEnabled = @YES;

CLXSDKConfig *sdkConfig = [[CLXSDKConfig alloc] init];
sdkConfig.metricsConfig = config;

[metricsTracker startWithConfig:sdkConfig];
```

## Database Schema

### metrics_events Table
```sql
CREATE TABLE IF NOT EXISTS metrics_events (
    id TEXT PRIMARY KEY,
    metricName TEXT NOT NULL,
    counter INTEGER NOT NULL DEFAULT 0,
    totalLatency INTEGER NOT NULL DEFAULT 0,
    sessionId TEXT,
    auctionId TEXT
);
```

## Tracked Metrics

### Method Calls (No Latency)
- `method_sdk_init` - SDK initialization
- `method_create_banner` - Banner ad creation
- `method_create_interstitial` - Interstitial ad creation
- `method_create_rewarded` - Rewarded ad creation
- `method_create_mrec` - MREC ad creation
- `method_create_native` - Native ad creation
- `method_set_hashed_user_id` - User ID setting
- `method_set_user_key_values` - User data setting
- `method_set_app_key_values` - App data setting
- `method_banner_refresh` - Banner refresh

### Network Calls (With Latency)
- `network_call_sdk_init_req` - SDK initialization request
- `network_call_geo_req` - Geo location request
- `network_call_bid_req` - Ad bid request

## Error Handling

### Database Errors
- Failed inserts are logged but don't crash the SDK
- Query failures return empty results
- Database connection issues are handled gracefully

### Network Errors
- Failed metric submissions are retried on next interval
- Timeout errors are logged and reported
- Network unavailability doesn't affect SDK functionality

### Encryption Errors
- Failed encryption logs error and skips that metric
- Invalid account IDs use fallback encryption
- Malformed payloads are discarded

## Performance Considerations

### Memory Usage
- Metrics are aggregated to minimize database size
- Successful sends trigger immediate cleanup
- Maximum metric retention prevents unbounded growth

### CPU Usage
- Metrics aggregation uses efficient in-memory operations
- Database operations are performed on background queue
- Encryption is lightweight XOR operation

### Network Usage
- Bulk sending minimizes network requests
- Configurable send intervals reduce frequency
- Compression and encryption reduce payload size

## Testing

### Unit Tests
- `CLXMetricsEventTests` - Event model validation
- `CLXMetricsTypeTests` - Type constant validation
- `CLXMetricsConfigTests` - Configuration logic
- `CLXMetricsTrackerImplTests` - Core functionality
- `CLXMetricsEventDaoTests` - Database operations
- `CLXEventAMTests` - Bulk API model

### Integration Tests
- `CLXMetricsIntegrationTests` - End-to-end flow
- Configuration-based filtering
- Concurrent operation safety
- Lifecycle management

## Android Parity

The iOS implementation achieves full parity with Android:

### ✅ Matching Features
- Identical metric type names
- Same aggregation logic (counter + totalLatency)
- Equivalent configuration options
- Similar encryption approach
- Bulk API format compatibility
- Periodic sending mechanism
- SQLite persistence layer
- Dependency injection pattern

### ✅ Matching Behavior
- Metrics triggered at same SDK entry points
- Network latency measurement approach
- Session-based metric grouping
- Automatic cleanup after successful sends
- Configuration-based enablement/disablement

## Debugging

### Environment Variables
Set `CLOUDX_VERBOSE_LOG=1` to see metrics logs:
```
[MetricsTrackerImpl] Tracking method call: method_create_banner
[MetricsTrackerImpl] Aggregated metric method_create_banner: counter=2, latency=0
[MetricsTrackerImpl] Sending 3 metrics events to bulk API
[EventTrackerBulkApi] Successfully sent bulk metrics
```

### Debug Utilities
Use `CLXMetricsDebugger` for advanced troubleshooting:

```objective-c
#ifdef DEBUG
// Get metrics tracker instance
id<CLXMetricsTrackerProtocol> tracker = [[CLXDIContainer shared] 
    resolveType:ServiceTypeSingleton class:[CLXMetricsTrackerImpl class]];

// Print comprehensive debug information
[tracker debugPrintStatus];

// Validate system integrity
NSArray<NSString *> *issues = [tracker validateSystem];
if (issues.count > 0) {
    NSLog(@"Metrics validation issues found: %@", issues);
}

// Enable enhanced debug mode for more verbose logging
[CLXMetricsDebugger enableEnhancedDebugMode];
#endif
```

### Common Issues
1. **No metrics being tracked**: Check if metrics are enabled in configuration
2. **Metrics not being sent**: Verify network connectivity and endpoint URL
3. **Database errors**: Check SQLite database permissions and disk space
4. **Encryption failures**: Verify accountId is set correctly
5. **Performance issues**: Use performance report to identify bottlenecks

## Migration Notes

### From CoreData to SQLite
- Legacy `CLXMetricsTracker` still handles CoreData session metrics
- New `CLXMetricsTrackerImpl` uses SQLite for performance metrics
- No data migration needed as SDK isn't live yet
- Both systems can coexist during transition period

### Breaking Changes
- None - all changes are additive
- Existing metrics functionality remains unchanged
- New metrics system is opt-in via configuration
