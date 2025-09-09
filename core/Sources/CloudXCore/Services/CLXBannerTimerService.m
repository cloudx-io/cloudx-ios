/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BannerTimerService.m
 * @brief Banner timer service implementation
 */

#import <CloudXCore/CLXBannerTimerService.h>
#import <CloudXCore/CLXLogger.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXBackgroundTimer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXBannerTimerService ()

@property (nonatomic, assign) NSTimeInterval timeCounter;
@property (nonatomic, strong) CLXBackgroundTimer *timer;
@property (nonatomic, copy, nullable) void (^completionBlock)(void);
@property (nonatomic, assign) BOOL needToResume;

@end

@implementation CLXBannerTimerService

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeCounter = 0;
        _timer = [CLXBackgroundTimer scheduleRepeatingTimerWithTimeInterval:1.0
                                                              queueLabel:@"com.cloudx.ads.service.timer.banner"];
        _needToResume = NO;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(appMovedToBackground)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(appMovedFromBackground)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
    }
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [self.timer suspend];
}

- (void)startCountDownWithDeadline:(NSTimeInterval)deadline
                       completion:(void (^)(void))completion {
    self.timeCounter = 0;
    self.completionBlock = completion;
    self.needToResume = YES;
    
    __weak typeof(self) weakSelf = self;
    self.timer.eventHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        strongSelf.timeCounter += 1;
        if (strongSelf.timeCounter > deadline) {
            [strongSelf.timer suspend];
            strongSelf.needToResume = NO;
            if (strongSelf.completionBlock) {
                strongSelf.completionBlock();
            }
        }
    };
    
    [self.timer resume];
}

- (void)appMovedToBackground {
    [self.timer suspend];
}

- (void)appMovedFromBackground {
    if (self.needToResume) {
        [self.timer resume];
    }
}

- (void)stop {
    [self.timer suspend];
}

@end

NS_ASSUME_NONNULL_END 