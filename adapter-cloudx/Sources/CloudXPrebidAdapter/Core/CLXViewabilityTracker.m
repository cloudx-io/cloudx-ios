//
//  CLXViewabilityTracker.m
//  CloudXPrebidAdapter
//
//  Advanced viewability tracking implementation for CloudX Prebid Adapter
//  
//  This class provides IAB-compliant viewability measurement including:
//  - High-frequency tracking (60 FPS) for smooth measurement
//  - IAB standard compliance (50% visible for 1 second)
//  - Occlusion detection and handling
//  - Historical measurement data collection
//  - Background/foreground state management
//  - Threshold-based viewability determination
//  - Real-time exposure tracking
//  - Performance-optimized measurement algorithms
//

#import "CLXViewabilityTracker.h"
#import <CloudXCore/CLXLogger.h>

/**
 * CLXViewabilityMeasurement - Individual viewability measurement data
 * 
 * Contains data for a single viewability measurement including
 * visibility percentage, timestamp, and measurement metadata.
 */
@implementation CLXViewabilityMeasurement
@end

/**
 * Private interface for CLXViewabilityTracker
 * 
 * Contains internal properties for tracking state, measurement data,
 * timing information, and notification handling that should not be exposed publicly.
 */
@interface CLXViewabilityTracker ()
@property (nonatomic, strong, readwrite) UIView *trackedView;
@property (nonatomic, strong) NSTimer *trackingTimer;
@property (nonatomic, assign, readwrite) BOOL isCurrentlyViewable;
@property (nonatomic, assign, readwrite) NSTimeInterval totalViewableTime;
@property (nonatomic, strong, readwrite) CLXViewabilityMeasurement *currentMeasurement;
@property (nonatomic, strong) NSMutableArray<CLXViewabilityMeasurement *> *measurementHistory;
@property (nonatomic, assign) NSTimeInterval viewableStartTime;
@property (nonatomic, assign) NSTimeInterval lastMeasurementTime;
@property (nonatomic, assign) BOOL hasMetThreshold;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXViewabilityTracker

/**
 * Initialize viewability tracker with target view
 * 
 * Sets up IAB-compliant viewability tracking including:
 * - High-frequency measurement timer (60 FPS)
 * - IAB standard configuration (50% visible for 1 second)
 * - Measurement history collection
 * - Background/foreground state handling
 * - Occlusion detection setup
 * 
 * @param view UIView to track for viewability
 * @return Initialized CLXViewabilityTracker instance
 */
- (instancetype)initWithView:(UIView *)view {
    self.logger = [[CLXLogger alloc] initWithCategory:@"CLXViewabilityTracker"];
    [self.logger info:[NSString stringWithFormat:@"🚀 [VIEWABILITY-INIT] CLXViewabilityTracker initialization started - Tracked view: %p (%@)", view, NSStringFromClass([view class])]];
    
    self = [super init];
    if (self) {
        [self.logger info:@"✅ [VIEWABILITY-INIT] Super init successful"];
        
        // Initialize core tracking properties
        _trackedView = view;
        _standard = CLXViewabilityStandardIAB;
        _viewabilityThreshold = 0.5; // 50% visibility threshold
        _timeThreshold = 1.0; // 1 second time threshold
        _measurementHistory = [NSMutableArray array];
        _currentMeasurement = [[CLXViewabilityMeasurement alloc] init];
        _hasMetThreshold = NO;
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [VIEWABILITY-INIT] Standard: IAB (50%% for 1 second), Viewability threshold: %.1f%%, Time threshold: %.1f seconds, Measurement history initialized", _viewabilityThreshold * 100, _timeThreshold]];
        
        // Register for app lifecycle notifications
        [self setupNotifications];
        [self.logger info:@"🎯 [VIEWABILITY-INIT] CLXViewabilityTracker initialization completed successfully - Notifications configured"];
    } else {
        [self.logger error:@"❌ [VIEWABILITY-INIT] Super init failed"];
    }
    return self;
}

/**
 * Cleanup resources and remove observers
 * Stops tracking and removes notification observers to prevent memory leaks
 */
- (void)dealloc {
    [self stopTracking];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 * Register for application lifecycle notifications
 * 
 * Monitors app backgrounding and foregrounding to pause/resume
 * viewability tracking appropriately.
 */
- (void)setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
               selector:@selector(applicationDidEnterBackground:) 
                   name:UIApplicationDidEnterBackgroundNotification 
                 object:nil];
    [center addObserver:self 
               selector:@selector(applicationWillEnterForeground:) 
                   name:UIApplicationWillEnterForegroundNotification 
                 object:nil];
}

#pragma mark - Public Methods

/**
 * Start viewability tracking with high-frequency measurements
 * 
 * Initiates 60 FPS tracking timer for smooth viewability measurement.
 * Performs initial measurement immediately upon start.
 * Only starts if not already tracking.
 */
- (void)startTracking {
    if (self.trackingTimer) return; // Already tracking
    
    // Start high-frequency tracking (60 FPS for smooth measurement)
    self.trackingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 
                                                         target:self 
                                                       selector:@selector(performViewabilityMeasurement) 
                                                       userInfo:nil 
                                                        repeats:YES];
    
    // Perform initial measurement
    [self performViewabilityMeasurement];
    
    [self.logger info:@"👁️ [VIEWABILITY] Started tracking with 60 FPS measurement"];
}

/**
 * Stop viewability tracking and perform final measurement
 * 
 * Invalidates tracking timer and performs final measurement
 * if the view is currently viewable. Updates total viewable time.
 */
- (void)stopTracking {
    [self.trackingTimer invalidate];
    self.trackingTimer = nil;
    
    // Final measurement if currently viewable
    if (self.isCurrentlyViewable) {
        [self updateViewableTime];
        [self setViewableState:NO];
    }
    
    [self.logger info:@"⏹️ [VIEWABILITY] Stopped tracking"];
}

- (void)checkViewability {
    [self performViewabilityMeasurement];
}

- (void)configureCustomStandard:(CGFloat)threshold timeRequirement:(NSTimeInterval)time {
    _standard = CLXViewabilityStandardCustom;
    _viewabilityThreshold = threshold;
    _timeThreshold = time;
}

- (NSArray<CLXViewabilityMeasurement *> *)getViewabilityHistory {
    return [self.measurementHistory copy];
}

- (void)reset {
    [self stopTracking];
    _totalViewableTime = 0;
    _viewableStartTime = 0;
    _lastMeasurementTime = 0;
    _hasMetThreshold = NO;
    [self.measurementHistory removeAllObjects];
    
    _currentMeasurement = [[CLXViewabilityMeasurement alloc] init];
    _isCurrentlyViewable = NO;
}

#pragma mark - Private Methods

- (void)performViewabilityMeasurement {
    static NSUInteger measurementCount = 0;
    measurementCount++;
    
    // Log every 60th measurement (once per second at 60 FPS) to avoid log spam
    BOOL shouldLog = (measurementCount % 60 == 0) || measurementCount < 5;
    
    if (shouldLog) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [VIEWABILITY-MEASURE] Performing measurement #%lu", (unsigned long)measurementCount]];
    }
    
    if (!self.trackedView || !self.trackedView.superview) {
        if (shouldLog) {
            [self.logger info:@"⚠️ [VIEWABILITY-MEASURE] View not available or not in superview hierarchy"];
        }
        [self setViewableState:NO];
        return;
    }
    
    CLXViewabilityMeasurement *measurement = [self calculateViewabilityMeasurement];
    
    if (shouldLog) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [VIEWABILITY-MEASURE] Calculated exposure: %.1f%% (threshold: %.1f%%), Exposed rect: %@", 
              measurement.exposedPercentage * 100, self.viewabilityThreshold * 100, NSStringFromCGRect(measurement.exposedRect)]];
    }
    
    // Update current measurement
    self.currentMeasurement = measurement;
    
    // Determine viewability based on threshold
    BOOL wasViewable = self.isCurrentlyViewable;
    BOOL isNowViewable = measurement.exposedPercentage >= self.viewabilityThreshold;
    
    if (isNowViewable != wasViewable) {
        [self.logger debug:[NSString stringWithFormat:@"🔄 [VIEWABILITY-STATE] State change: %@ -> %@", 
              wasViewable ? @"VIEWABLE" : @"NOT_VIEWABLE",
              isNowViewable ? @"VIEWABLE" : @"NOT_VIEWABLE"]];
        [self setViewableState:isNowViewable];
    }
    
    if (self.isCurrentlyViewable) {
        [self updateViewableTime];
        
        // Check if we've met the time threshold
        NSTimeInterval viewableTime = measurement.viewableTime;
        if (!self.hasMetThreshold && viewableTime >= self.timeThreshold) {
            self.hasMetThreshold = YES;
            [self.logger info:[NSString stringWithFormat:@"🎯 [VIEWABILITY-THRESHOLD] IAB viewability threshold met! Viewable time: %.2f seconds", viewableTime]];
            if ([self.delegate respondsToSelector:@selector(viewabilityTracker:didMeetViewabilityThreshold:)]) {
                [self.delegate viewabilityTracker:self didMeetViewabilityThreshold:measurement];
            }
        } else if (shouldLog && viewableTime > 0) {
            [self.logger debug:[NSString stringWithFormat:@"⏱️ [VIEWABILITY-TIME] Current viewable time: %.2f/%.1f seconds", viewableTime, self.timeThreshold]];
        }
    }
    
    // Add to history (limit to last 100 measurements for memory efficiency)
    [self.measurementHistory addObject:measurement];
    if (self.measurementHistory.count > 100) {
        [self.measurementHistory removeObjectAtIndex:0];
        if (shouldLog) {
            [self.logger debug:[NSString stringWithFormat:@"🗄️ [VIEWABILITY-HISTORY] Pruned old measurement, history size: %lu", (unsigned long)self.measurementHistory.count]];
        }
    }
    
    // Notify delegate of exposure update (but don't log every time to avoid spam)
    if ([self.delegate respondsToSelector:@selector(viewabilityTracker:didUpdateExposure:)]) {
        [self.delegate viewabilityTracker:self didUpdateExposure:measurement];
    }
}

- (CLXViewabilityMeasurement *)calculateViewabilityMeasurement {
    CLXViewabilityMeasurement *measurement = [[CLXViewabilityMeasurement alloc] init];
    measurement.timestamp = [NSDate timeIntervalSinceReferenceDate];
    
    // Get view frame in window coordinates
    UIWindow *window = self.trackedView.window;
    if (!window) {
        measurement.exposedPercentage = 0.0;
        measurement.isViewable = NO;
        return measurement;
    }
    
    CGRect viewFrame = [self.trackedView convertRect:self.trackedView.bounds toView:window];
    CGRect windowBounds = window.bounds;
    
    // Calculate intersection with window
    CGRect intersection = CGRectIntersection(viewFrame, windowBounds);
    
    if (CGRectIsEmpty(intersection)) {
        measurement.exposedPercentage = 0.0;
        measurement.exposedRect = CGRectZero;
        measurement.occludedRect = viewFrame;
        measurement.isViewable = NO;
        return measurement;
    }
    
    // Check for occlusion by other views
    intersection = [self getVisibleRectConsideringOcclusion:viewFrame inWindow:window];
    
    // Calculate exposure percentage
    CGFloat viewArea = viewFrame.size.width * viewFrame.size.height;
    CGFloat visibleArea = intersection.size.width * intersection.size.height;
    
    measurement.exposedPercentage = viewArea > 0 ? (visibleArea / viewArea) : 0.0;
    measurement.exposedRect = intersection;
    measurement.occludedRect = CGRectMake(viewFrame.origin.x, viewFrame.origin.y,
                                         viewFrame.size.width - intersection.size.width,
                                         viewFrame.size.height - intersection.size.height);
    measurement.isViewable = measurement.exposedPercentage >= self.viewabilityThreshold;
    measurement.viewableTime = self.isCurrentlyViewable ? 
        (measurement.timestamp - self.viewableStartTime) : 0.0;
    
    return measurement;
}

- (CGRect)getVisibleRectConsideringOcclusion:(CGRect)viewFrame inWindow:(UIWindow *)window {
    CGRect visibleRect = CGRectIntersection(viewFrame, window.bounds);
    
    // Check for occlusion by sibling views and parent view clipping
    UIView *currentView = self.trackedView;
    
    while (currentView.superview) {
        UIView *parent = currentView.superview;
        
        // Check parent bounds clipping
        if (parent.clipsToBounds) {
            CGRect parentFrame = [parent convertRect:parent.bounds toView:window];
            visibleRect = CGRectIntersection(visibleRect, parentFrame);
        }
        
        // Check sibling occlusion
        NSInteger currentIndex = [parent.subviews indexOfObject:currentView];
        for (NSInteger i = currentIndex + 1; i < parent.subviews.count; i++) {
            UIView *sibling = parent.subviews[i];
            if (!sibling.hidden && sibling.alpha > 0.01) {
                CGRect siblingFrame = [sibling convertRect:sibling.bounds toView:window];
                CGRect overlap = CGRectIntersection(visibleRect, siblingFrame);
                if (!CGRectIsEmpty(overlap)) {
                    // Subtract occluded area (simplified - assumes full occlusion)
                    visibleRect = [self subtractRect:overlap fromRect:visibleRect];
                }
            }
        }
        
        currentView = parent;
    }
    
    return visibleRect;
}

- (CGRect)subtractRect:(CGRect)subtractRect fromRect:(CGRect)fromRect {
    // Simplified occlusion calculation - returns the largest remaining rectangle
    // In a full implementation, this would handle complex occlusion scenarios
    CGRect intersection = CGRectIntersection(fromRect, subtractRect);
    if (CGRectIsEmpty(intersection)) {
        return fromRect;
    }
    
    // Calculate remaining area after subtraction
    CGFloat totalArea = fromRect.size.width * fromRect.size.height;
    CGFloat occludedArea = intersection.size.width * intersection.size.height;
    CGFloat remainingArea = totalArea - occludedArea;
    
    if (remainingArea <= 0) {
        return CGRectZero;
    }
    
    // Return approximate remaining rectangle
    CGFloat ratio = sqrt(remainingArea / totalArea);
    return CGRectMake(fromRect.origin.x, fromRect.origin.y,
                     fromRect.size.width * ratio,
                     fromRect.size.height * ratio);
}

- (void)setViewableState:(BOOL)viewable {
    if (_isCurrentlyViewable == viewable) return;
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    if (viewable) {
        // Became viewable
        _isCurrentlyViewable = YES;
        _viewableStartTime = now;
    } else {
        // Became non-viewable
        if (_isCurrentlyViewable) {
            [self updateViewableTime];
        }
        _isCurrentlyViewable = NO;
        _hasMetThreshold = NO; // Reset threshold flag when not viewable
    }
    
    _lastMeasurementTime = now;
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(viewabilityTracker:didChangeViewability:measurement:)]) {
        [self.delegate viewabilityTracker:self didChangeViewability:_isCurrentlyViewable measurement:self.currentMeasurement];
    }
}

- (void)updateViewableTime {
    if (_isCurrentlyViewable && _viewableStartTime > 0) {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval sessionTime = now - _viewableStartTime;
        _totalViewableTime += sessionTime;
        _viewableStartTime = now; // Reset for next calculation
    }
}

#pragma mark - Notification Handlers

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.isCurrentlyViewable) {
        [self updateViewableTime];
        [self setViewableState:NO];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // Trigger immediate measurement when app returns to foreground
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self performViewabilityMeasurement];
    });
}

@end