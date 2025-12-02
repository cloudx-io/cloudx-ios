/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides visual feedback when ads are clicked while visual debugging is enabled.
 * Shows different states: pending (waiting for adapter) and confirmed (adapter responded).
 */
@interface CLXDebugClickFeedback : NSObject

/**
 * Show a "click pending" animation - flashing white border.
 * Call this when user taps but before adapter confirms.
 * @param view The view to show the effect on
 */
+ (void)showClickPendingOnView:(UIView *)view;

/**
 * Stop the pending animation and show confirmed state - green border flash.
 * Call this when adapter confirms the click.
 * @param view The view to show the effect on
 */
+ (void)showClickConfirmedOnView:(UIView *)view;

/**
 * Show a click ripple effect on the given view.
 * @param view The view to show the effect on (typically an ad container)
 * @param point The touch point within the view
 */
+ (void)showClickFeedbackOnView:(UIView *)view atPoint:(CGPoint)point;

/**
 * Show a border highlight effect on the given view (green - confirmed).
 * @param view The view to highlight
 */
+ (void)showBorderHighlightOnView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
