//
//  CLXSessionMetricsTracker.m
//  CloudXCore
//
//  Created by CloudX iOS Team
//  Copyright (c) 2024 CloudX. All rights reserved.
//

#import <CloudXCore/CLXSessionMetricsTracker.h>
#import "CLXLogger.h"

// Session timeout: 30 minutes in seconds
static const NSTimeInterval kSessionTimeoutSeconds = 30 * 60;

/**
 * Session ad format enum (internal implementation detail).
 * Maps CLXAdType to session format categories.
 */
typedef NS_ENUM(NSInteger, CLXSessionAdFormat) {
    CLXSessionAdFormatBanner = 0,
    CLXSessionAdFormatMediumRectangle = 1,
    CLXSessionAdFormatFull = 2,
    CLXSessionAdFormatNative = 3,
    CLXSessionAdFormatRewarded = 4,
    CLXSessionAdFormatCount  // Must be last - used for array sizing
};

@interface CLXSessionMetricsTracker ()

// Thread safety
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) CLXLogger *logger;

// Clock provider for testing (Dependency Inversion Principle)
@property (nonatomic, copy) NSTimeInterval (^clockProvider)(void);

// Session state (protected by queue)
@property (nonatomic, assign) NSTimeInterval sessionStartTime;
@property (nonatomic, assign) NSTimeInterval lastActivityTime;
@property (nonatomic, assign) NSInteger globalCount;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *formatCounts;  // Array of NSInteger
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *placementCounts;

// Time-to-first-ad tracking
@property (nonatomic, assign) NSTimeInterval sdkInitTime;
@property (nonatomic, assign) BOOL firstImpressionTracked;
@property (nonatomic, assign) NSInteger timeToFirstAdMs;
@property (nonatomic, copy, nullable) void (^timeToFirstAdCallback)(NSInteger);

@end

@implementation CLXSessionMetricsTracker

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static CLXSessionMetricsTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initInternal];
    });
    return sharedInstance;
}

#pragma mark - Initialization

- (instancetype)initInternal {
    self = [super init];
    if (self) {
        // Create serial queue for thread safety
        _queue = dispatch_queue_create("io.cloudx.session-metrics", DISPATCH_QUEUE_SERIAL);
        _logger = [[CLXLogger alloc] initWithCategory:@"SessionMetricsTracker"];
        
        // Default clock: monotonic system uptime
        // Monotonic clock is immune to system time changes (user adjusts time, NTP sync, etc.)
        _clockProvider = ^NSTimeInterval {
            return [NSProcessInfo processInfo].systemUptime;
        };
        
        // Initialize state
        _sessionStartTime = 0;
        _lastActivityTime = 0;
        _globalCount = 0;
        
        // Initialize format counts array with zeros
        _formatCounts = [NSMutableArray arrayWithCapacity:CLXSessionAdFormatCount];
        for (NSInteger i = 0; i < CLXSessionAdFormatCount; i++) {
            [_formatCounts addObject:@0];
        }
        
        _placementCounts = [NSMutableDictionary dictionary];
        
        // Time-to-first-ad tracking
        _sdkInitTime = 0;
        _firstImpressionTracked = NO;
        _timeToFirstAdMs = -1;
        
        [_logger debug:@"SessionMetricsTracker initialized"];
    }
    return self;
}

#pragma mark - Public API (CLXSessionMetricsTrackerProtocol)

- (void)recordImpressionForPlacement:(NSString *)placementName adType:(NSInteger)adType {
    // Validate input (fail fast)
    if (!placementName || placementName.length == 0) {
        [self.logger debug:@"recordImpression called with nil/empty placementName - ignoring"];
        return;
    }
    
    // Synchronous dispatch ensures thread safety and prevents race conditions
    dispatch_sync(self.queue, ^{
        NSTimeInterval now = self.clockProvider();
        [self maybeResetForInactivity:now];
        
        CLXSessionAdFormat format = [self sessionFormatFromAdType:adType];
        
        // Initialize session start time on first impression
        if (self.sessionStartTime == 0) {
            self.sessionStartTime = now;
            [self.logger debug:[NSString stringWithFormat:@"Session started at %.2f", now]];
        }
        self.lastActivityTime = now;
        
        // Increment counters atomically
        self.globalCount += 1;
        
        NSInteger currentFormatCount = [self.formatCounts[format] integerValue];
        self.formatCounts[format] = @(currentFormatCount + 1);
        
        NSInteger currentPlacementCount = [self.placementCounts[placementName] integerValue];
        self.placementCounts[placementName] = @(currentPlacementCount + 1);
        
        // Track time-to-first-ad (only once per session after SDK init)
        if (!self.firstImpressionTracked && self.sdkInitTime > 0) {
            self.timeToFirstAdMs = (NSInteger)((now - self.sdkInitTime) * 1000);
            self.firstImpressionTracked = YES;
            
            [self.logger info:[NSString stringWithFormat:
                @"Time-to-first-ad: %ldms", (long)self.timeToFirstAdMs]];
            
            // Invoke callback if set (for metrics reporting)
            // Dispatch async to avoid holding the queue during callback execution
            // and prevent potential deadlock if callback accesses this tracker
            void (^callback)(NSInteger) = self.timeToFirstAdCallback;
            NSInteger ttfaMs = self.timeToFirstAdMs;
            if (callback) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    callback(ttfaMs);
                });
            }
        }
        
        [self.logger debug:[NSString stringWithFormat:
            @"Recorded impression - placement:'%@' format:%ld globalCount:%ld",
            placementName, (long)format, (long)self.globalCount]];
    });
}

- (CLXSessionMetrics *)getMetrics {
    __block CLXSessionMetrics *metrics = nil;
    
    dispatch_sync(self.queue, ^{
        NSTimeInterval now = self.clockProvider();
        [self maybeResetForInactivity:now];
        
        // Calculate duration since first impression
        float durationSeconds = 0.0f;
        if (self.sessionStartTime > 0) {
            durationSeconds = MAX(0.0f, (float)(now - self.sessionStartTime));
        }
        
        // Create immutable snapshot (value object pattern)
        metrics = [[CLXSessionMetrics alloc] initWithDepth:(float)self.globalCount
                                               bannerDepth:[self.formatCounts[CLXSessionAdFormatBanner] floatValue]
                                      mediumRectangleDepth:[self.formatCounts[CLXSessionAdFormatMediumRectangle] floatValue]
                                                 fullDepth:[self.formatCounts[CLXSessionAdFormatFull] floatValue]
                                               nativeDepth:[self.formatCounts[CLXSessionAdFormatNative] floatValue]
                                             rewardedDepth:[self.formatCounts[CLXSessionAdFormatRewarded] floatValue]
                                           durationSeconds:durationSeconds];
        
        [self.logger debug:[NSString stringWithFormat:@"getMetrics: %@", metrics]];
    });
    
    return metrics;
}

- (NSInteger)getPlacementDepthForPlacement:(NSString *)placementName {
    if (!placementName) {
        return 0;
    }
    
    __block NSInteger depth = 0;
    dispatch_sync(self.queue, ^{
        depth = [self.placementCounts[placementName] integerValue];
    });
    return depth;
}

- (void)resetPlacement:(NSString *)placementName {
    if (!placementName) {
        return;
    }
    
    dispatch_sync(self.queue, ^{
        [self.placementCounts removeObjectForKey:placementName];
        [self.logger info:[NSString stringWithFormat:@"Reset placement: %@", placementName]];
    });
}

- (void)resetAll {
    dispatch_sync(self.queue, ^{
        [self resetState];
        [self.logger info:@"Reset all session metrics"];
    });
}

#pragma mark - Time-to-First-Ad Tracking

- (void)recordSDKInitialization {
    dispatch_sync(self.queue, ^{
        if (self.sdkInitTime == 0) {
            self.sdkInitTime = self.clockProvider();
            [self.logger debug:[NSString stringWithFormat:@"SDK init recorded at %.2f", self.sdkInitTime]];
        }
    });
}

- (NSInteger)getTimeToFirstAdMs {
    __block NSInteger result = -1;
    dispatch_sync(self.queue, ^{
        result = self.firstImpressionTracked ? self.timeToFirstAdMs : -1;
    });
    return result;
}

- (void)setTimeToFirstAdCallback:(void (^)(NSInteger))callback {
    // Use dispatch_async to avoid potential deadlock if called from within the queue
    // Setter doesn't need to block - fire-and-forget is appropriate here
    void (^copiedCallback)(NSInteger) = [callback copy];
    dispatch_async(self.queue, ^{
        // Use ivar directly to avoid infinite recursion (this IS the setter)
        _timeToFirstAdCallback = copiedCallback;
        [self.logger debug:@"Time-to-first-ad callback configured"];
    });
}

#pragma mark - Testing Support

- (void)setClockProviderForTesting:(NSTimeInterval (^)(void))clockProvider {
    dispatch_sync(self.queue, ^{
        self.clockProvider = clockProvider;
        [self.logger debug:@"Clock provider set for testing"];
    });
}

- (void)resetClockForTesting {
    dispatch_sync(self.queue, ^{
        self.clockProvider = ^NSTimeInterval {
            return [NSProcessInfo processInfo].systemUptime;
        };
        [self.logger debug:@"Clock provider reset to default"];
    });
}

#pragma mark - Private Methods

/**
 * Checks if session has timed out due to inactivity and resets if needed.
 * Called before every operation to ensure session freshness.
 *
 * @param now Current time from clock provider
 */
- (void)maybeResetForInactivity:(NSTimeInterval)now {
    if (self.lastActivityTime == 0) {
        return;  // No activity yet, nothing to timeout
    }
    
    NSTimeInterval timeSinceLastActivity = now - self.lastActivityTime;
    if (timeSinceLastActivity >= kSessionTimeoutSeconds) {
        [self.logger info:[NSString stringWithFormat:
            @"Session timeout (%.1f minutes) - resetting metrics",
            timeSinceLastActivity / 60.0]];
        [self resetState];
    }
}

/**
 * Resets all session state to initial values.
 * Assumes caller has already acquired queue lock.
 */
- (void)resetState {
    self.globalCount = 0;
    
    // Reset all format counts to zero
    for (NSInteger i = 0; i < CLXSessionAdFormatCount; i++) {
        self.formatCounts[i] = @0;
    }
    
    [self.placementCounts removeAllObjects];
    self.sessionStartTime = 0;
    self.lastActivityTime = 0;
    
    // Reset time-to-first-ad tracking
    // Note: We keep the callback - it persists across session resets
    // The callback will fire again on the next session's first impression
    self.sdkInitTime = 0;
    self.firstImpressionTracked = NO;
    self.timeToFirstAdMs = -1;
}

/**
 * Maps CLXAdType enum to internal session format enum.
 * This decouples session tracking from public ad type definitions.
 *
 * @param adType Public ad type enum value
 * @return Internal session format enum value
 */
- (CLXSessionAdFormat)sessionFormatFromAdType:(NSInteger)adType {
    // Map based on CLXAdType enum values from CLXAdType.h:
    // CLXAdTypeInterstitial = 0
    // CLXAdTypeRewarded = 1
    // CLXAdTypeBanner = 2
    // CLXAdTypeMrec = 3
    // CLXAdTypeNative = 4
    switch (adType) {
        case 0:  // CLXAdTypeInterstitial
            return CLXSessionAdFormatFull;
        case 1:  // CLXAdTypeRewarded
            return CLXSessionAdFormatRewarded;
        case 2:  // CLXAdTypeBanner
            return CLXSessionAdFormatBanner;
        case 3:  // CLXAdTypeMrec
            return CLXSessionAdFormatMediumRectangle;
        case 4:  // CLXAdTypeNative
            return CLXSessionAdFormatNative;
        default:
            [self.logger debug:[NSString stringWithFormat:
                @"Unknown ad type: %ld, defaulting to Banner", (long)adType]];
            return CLXSessionAdFormatBanner;
    }
}

#pragma mark - NSObject

- (NSString *)description {
    __block NSString *desc = nil;
    dispatch_sync(self.queue, ^{
        desc = [NSString stringWithFormat:
                @"<CLXSessionMetricsTracker: globalCount=%ld, sessionStart=%.2f, lastActivity=%.2f, placements=%lu>",
                (long)self.globalCount,
                self.sessionStartTime,
                self.lastActivityTime,
                (unsigned long)self.placementCounts.count];
    });
    return desc;
}

@end

