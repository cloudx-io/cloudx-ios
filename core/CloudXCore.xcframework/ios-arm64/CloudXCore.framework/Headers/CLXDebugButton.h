/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Floating draggable debug button that appears when testMode is enabled.
 * Tapping opens the debug log viewer. Flashes red on ad errors.
 */
@interface CLXDebugButton : UIButton

/**
 * Called when button position changes during drag.
 */
@property (nonatomic, copy, nullable) void (^onPositionChange)(CGPoint center);

/**
 * Create a debug button with default styling.
 */
- (instancetype)init;

/**
 * Flash the button red for 2 seconds to indicate an error occurred.
 */
- (void)flashError;

/**
 * Save the current position to UserDefaults for persistence.
 */
- (void)savePosition;

/**
 * Restore the saved position from UserDefaults.
 */
- (void)restorePosition;

@end

NS_ASSUME_NONNULL_END

