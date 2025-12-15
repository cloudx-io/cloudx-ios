/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXUIApplicationProxy.h"

@implementation CLXUIApplicationProxy

static BOOL _isAppEnvironmentCached = NO;
static BOOL _isAppEnvironmentValue = NO;

+ (BOOL)isAppEnvironment {
    // Cache the result - this won't change during runtime
    if (!_isAppEnvironmentCached) {
        Class appClass = NSClassFromString(@"UIApplication");
        _isAppEnvironmentValue = (appClass != nil && [appClass respondsToSelector:@selector(sharedApplication)]);
        _isAppEnvironmentCached = YES;
    }
    return _isAppEnvironmentValue;
}

+ (UIApplication *)sharedApplicationIfAvailable {
    if (![self isAppEnvironment]) {
        return nil;
    }
    // Safe to call - we verified it exists above
    return [UIApplication sharedApplication];
}

+ (UIWindowScene *)activeWindowScene {
    UIApplication *app = [self sharedApplicationIfAvailable];
    if (!app) {
        return nil;
    }
    
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
    }
    
    // Fallback: return any foreground scene (inactive but visible)
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (scene.activationState == UISceneActivationStateForegroundInactive) {
            return (UIWindowScene *)scene;
        }
    }
    
    return nil;
}

+ (UIWindow *)keyWindow {
    UIWindowScene *scene = [self activeWindowScene];
    if (!scene) {
        return nil;
    }
    
    // Find the key window in this scene
    for (UIWindow *window in scene.windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    
    // Fallback: return first window if no key window found
    return scene.windows.firstObject;
}

+ (UIEdgeInsets)safeAreaInsets {
    UIWindow *window = [self keyWindow];
    return window ? window.safeAreaInsets : UIEdgeInsetsZero;
}

@end
