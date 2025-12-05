/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Manages the debug overlay UI when testMode is enabled.
 * Shows a floating debug button that opens the log viewer.
 */
@interface CLXDebugOverlayManager : NSObject

/**
 * Shared singleton instance.
 */
+ (instancetype)shared;

/**
 * Show the debug overlay on the main window.
 * Only shows if testMode is enabled.
 */
- (void)showIfEnabled;

/**
 * Hide and remove the debug overlay.
 */
- (void)hide;

/**
 * Flash the debug button red to indicate an error occurred.
 * Call this when ad load or display fails.
 */
- (void)flashError;

/**
 * Check if the overlay is currently visible.
 */
@property (nonatomic, readonly) BOOL isVisible;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

