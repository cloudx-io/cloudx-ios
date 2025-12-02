/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDebugClickFeedback.h"
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

static NSString *const kPendingPulseAnimationKey = @"CLXPendingPulseAnimation";

@implementation CLXDebugClickFeedback

+ (BOOL)isVisualDebuggingEnabled {
    // Visual debugging is completely separate from testMode
    return [CloudXCore isVisualDebuggingEnabled];
}

#pragma mark - Click Pending (Pulsing White Border)

+ (void)showClickPendingOnView:(UIView *)view {
    if (![self isVisualDebuggingEnabled] || !view) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set initial border
        view.layer.borderWidth = 3.0;
        view.layer.borderColor = [UIColor whiteColor].CGColor;
        
        // Pulse between white and dark gray for visibility on any background
        // White visible on dark ads, dark gray visible on white ads
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
        pulseAnimation.fromValue = (__bridge id)[UIColor whiteColor].CGColor;
        pulseAnimation.toValue = (__bridge id)[UIColor colorWithWhite:0.2 alpha:1.0].CGColor;  // Dark gray
        pulseAnimation.duration = 0.4;
        pulseAnimation.autoreverses = YES;
        pulseAnimation.repeatCount = HUGE_VALF;
        [view.layer addAnimation:pulseAnimation forKey:kPendingPulseAnimationKey];
    });
}

+ (void)stopPendingAnimationOnView:(UIView *)view {
    if (!view) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [view.layer removeAnimationForKey:kPendingPulseAnimationKey];
        view.layer.borderWidth = 0;
        view.layer.borderColor = nil;
    });
}

#pragma mark - Click Confirmed (Green Border Flash)

+ (void)showClickConfirmedOnView:(UIView *)view {
    if (![self isVisualDebuggingEnabled] || !view) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // First stop the pending white border animation
        [view.layer removeAnimationForKey:kPendingPulseAnimationKey];
        // Then show green border (which will fade to nothing)
        [self showBorderHighlightOnView:view];
    });
}

#pragma mark - Legacy Methods

+ (void)showClickFeedbackOnView:(UIView *)view atPoint:(CGPoint)point {
    if (![self isVisualDebuggingEnabled]) return;
    if (!view) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create ripple circle
        CGFloat rippleSize = 60.0;
        UIView *ripple = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rippleSize, rippleSize)];
        ripple.center = point;
        ripple.backgroundColor = [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:0.4];
        ripple.layer.cornerRadius = rippleSize / 2.0;
        ripple.transform = CGAffineTransformMakeScale(0.3, 0.3);
        ripple.alpha = 1.0;
        
        [view addSubview:ripple];
        
        // Animate ripple expanding and fading
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            ripple.transform = CGAffineTransformMakeScale(2.0, 2.0);
            ripple.alpha = 0;
        } completion:^(BOOL finished) {
            [ripple removeFromSuperview];
        }];
        
        // Also show border highlight
        [self showBorderHighlightOnView:view];
    });
}

+ (void)showBorderHighlightOnView:(UIView *)view {
    if (![self isVisualDebuggingEnabled]) return;
    if (!view) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Apply green highlight border (confirmed click)
        view.layer.borderColor = [UIColor colorWithRed:0.3 green:0.8 blue:0.4 alpha:1.0].CGColor;
        view.layer.borderWidth = 3.0;
        
        // Reset to no border after brief display
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            view.layer.borderColor = nil;
            view.layer.borderWidth = 0;
        });
    });
}

@end
