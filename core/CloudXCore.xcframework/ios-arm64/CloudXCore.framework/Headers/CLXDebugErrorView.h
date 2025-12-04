/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error display view shown inside ad containers when load/display fails.
 * Only visible when testMode is enabled.
 */
@interface CLXDebugErrorView : UIView

/**
 * Create an error view with the given error message.
 * @param title Error title (e.g., "Load Failed", "Display Failed")
 * @param message Error message from the callback
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;

/**
 * Create an error view sized to fit a container.
 * @param frame The frame of the container
 * @param title Error title
 * @param message Error message
 */
+ (instancetype)errorViewWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END

