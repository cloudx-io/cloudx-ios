/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Proxy for UIApplication access that handles App Extension compatibility.
 *
 * UIApplication is not available in App Extensions (widgets, keyboard extensions, etc.).
 * This class provides safe access to UIApplication functionality, returning nil/safe defaults
 * when running in an extension context.
 *
 * All methods are safe to call from any context - they will simply return nil in extensions.
 */
@interface CLXUIApplicationProxy : NSObject

/// Returns YES if running in a full app context (UIApplication available), NO in extensions.
@property (class, nonatomic, readonly) BOOL isAppEnvironment;

/// Returns the key window from the active foreground scene, or nil in extensions.
@property (class, nonatomic, readonly, nullable) UIWindow *keyWindow;

/// Returns the active foreground window scene, or nil in extensions/background.
@property (class, nonatomic, readonly, nullable) UIWindowScene *activeWindowScene;

/// Returns safe area insets from the key window, or UIEdgeInsetsZero if unavailable.
@property (class, nonatomic, readonly) UIEdgeInsets safeAreaInsets;

@end

NS_ASSUME_NONNULL_END
