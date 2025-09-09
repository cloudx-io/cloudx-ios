/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BackgroundTimer.m
 * @brief Background timer implementation
 */

#import <CloudXCore/CLXBackgroundTimer.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BackgroundTimerState) {
    BackgroundTimerStateSuspended,
    BackgroundTimerStateResumed
};

@interface CLXBackgroundTimer ()

@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) BackgroundTimerState state;
@property (nonatomic, assign) BOOL isRepeating;

@end

@implementation CLXBackgroundTimer

+ (instancetype)scheduleRepeatingTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                            queueLabel:(NSString *)queueLabel {
    return [[self alloc] initWithTimeInterval:timeInterval
                                   queueLabel:queueLabel
                                  isRepeating:YES];
}

+ (instancetype)scheduleTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                   queueLabel:(NSString *)queueLabel {
    return [[self alloc] initWithTimeInterval:timeInterval
                                   queueLabel:queueLabel
                                  isRepeating:YES];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
                          queueLabel:(NSString *)queueLabel
                         isRepeating:(BOOL)isRepeating {
    self = [super init];
    if (self) {
        _timeInterval = timeInterval;
        _queue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _isRepeating = isRepeating;
        _state = BackgroundTimerStateSuspended;
        
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
        if (_timer) {
            if (isRepeating) {
                dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), (uint64_t)(timeInterval * NSEC_PER_SEC), 0);
            } else {
                dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), DISPATCH_TIME_FOREVER, 0);
            }
            
            __weak typeof(self) weakSelf = self;
            dispatch_source_set_event_handler(_timer, ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && strongSelf.eventHandler) {
                    strongSelf.eventHandler();
                }
            });
        }
    }
    return self;
}

- (void)resume {
    if (self.state == BackgroundTimerStateSuspended && self.timer) {
        dispatch_resume(self.timer);
        self.state = BackgroundTimerStateResumed;
    }
}

- (void)suspend {
    if (self.state == BackgroundTimerStateResumed && self.timer) {
        dispatch_suspend(self.timer);
        self.state = BackgroundTimerStateSuspended;
    }
}

- (void)dealloc {
    if (_timer) {
        if (self.state == BackgroundTimerStateSuspended) {
            dispatch_resume(_timer);
        }
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

@end

NS_ASSUME_NONNULL_END 