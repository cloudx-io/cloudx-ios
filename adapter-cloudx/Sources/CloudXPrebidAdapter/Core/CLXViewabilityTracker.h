//
//  CLXViewabilityTracker.h
//  CloudXPrebidAdapter
//
//  Advanced viewability tracking with IAB compliance
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXViewabilityTracker;

/**
 * Viewability tracking standards
 */
typedef NS_ENUM(NSInteger, CLXViewabilityStandard) {
    CLXViewabilityStandardIAB,      // 50% visible for 1 second
    CLXViewabilityStandardMRC,      // 50% visible for 1 second  
    CLXViewabilityStandardVideo,    // 50% visible for 2 seconds for video
    CLXViewabilityStandardCustom
};

/**
 * Viewability measurement data
 */
@interface CLXViewabilityMeasurement : NSObject
@property (nonatomic, assign) CGFloat exposedPercentage;
@property (nonatomic, assign) CGRect exposedRect;
@property (nonatomic, assign) CGRect occludedRect;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL isViewable;
@property (nonatomic, assign) NSTimeInterval viewableTime;
@end

/**
 * Delegate protocol for viewability events
 */
@protocol CLXViewabilityTrackerDelegate <NSObject>

@optional
- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didChangeViewability:(BOOL)viewable measurement:(CLXViewabilityMeasurement *)measurement;
- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didUpdateExposure:(CLXViewabilityMeasurement *)measurement;
- (void)viewabilityTracker:(CLXViewabilityTracker *)tracker didMeetViewabilityThreshold:(CLXViewabilityMeasurement *)measurement;

@end

/**
 * Advanced viewability tracker with IAB compliance and intersection observer
 */
@interface CLXViewabilityTracker : NSObject

@property (nonatomic, weak) id<CLXViewabilityTrackerDelegate> delegate;
@property (nonatomic, strong, readonly) UIView *trackedView;
@property (nonatomic, assign) CLXViewabilityStandard standard;
@property (nonatomic, assign) CGFloat viewabilityThreshold; // Default 0.5 (50%)
@property (nonatomic, assign) NSTimeInterval timeThreshold; // Default 1.0 second
@property (nonatomic, assign, readonly) BOOL isCurrentlyViewable;
@property (nonatomic, assign, readonly) NSTimeInterval totalViewableTime;
@property (nonatomic, strong, readonly) CLXViewabilityMeasurement *currentMeasurement;

/**
 * Initialize with view to track
 */
- (instancetype)initWithView:(UIView *)view;

/**
 * Start tracking viewability
 */
- (void)startTracking;

/**
 * Stop tracking viewability  
 */
- (void)stopTracking;

/**
 * Manually trigger viewability check (useful for scroll events)
 */
- (void)checkViewability;

/**
 * Configure custom viewability parameters
 */
- (void)configureCustomStandard:(CGFloat)threshold timeRequirement:(NSTimeInterval)time;

/**
 * Get viewability history for analytics
 */
- (NSArray<CLXViewabilityMeasurement *> *)getViewabilityHistory;

/**
 * Reset viewability tracking
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END