#import "CLXSyntheticTouch.h"
#import <objc/message.h>

@implementation CLXSyntheticTouch

/// Traverses the view hierarchy depth-first to find the deepest WebKit-related
/// subview at a given window-coordinate point.
///
/// Ad SDKs often place transparent UIView overlays on top of WKWebViews for
/// click tracking. For dismiss testing, we need to bypass those overlays and
/// reach the WebKit content where close buttons live. For click testing,
/// callers should use hitTest: instead (which returns the overlay).
///
/// Prefers WKChildScrollView (the scroll container inside WKWebView) because
/// WebKit's gesture recognizers are attached there — tapping it produces the
/// same effect as a real user tap on the web content.
+ (UIView *)findWebContentViewAtPoint:(CGPoint)windowPoint inView:(UIView *)view {
    for (NSInteger i = (NSInteger)view.subviews.count - 1; i >= 0; i--) {
        UIView *subview = view.subviews[i];
        if (subview.hidden || subview.alpha < 0.1) continue;
        CGPoint local = [subview convertPoint:windowPoint fromView:nil];
        if (![subview pointInside:local withEvent:nil]) continue;

        UIView *found = [self findWebContentViewAtPoint:windowPoint inView:subview];
        if (found) return found;
    }

    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"WKChildScrollView"] ||
        [view isKindOfClass:NSClassFromString(@"WKWebView")]) {
        return view;
    }
    return nil;
}

+ (BOOL)tapAtPoint:(CGPoint)windowPoint onView:(UIView *)targetView inWindow:(UIWindow *)window {
    if (!window || !targetView) return NO;

    NSLog(@"[SyntheticTouch] point=(%.0f,%.0f) hitView=%@ frame=%@",
          windowPoint.x, windowPoint.y,
          NSStringFromClass([targetView class]),
          NSStringFromCGRect([targetView convertRect:targetView.bounds toView:nil]));

    UITouch *touch = [[UITouch alloc] init];

    // These selectors are UITouch private API — the only mechanism to construct
    // a touch event that UIKit's gesture recognizer pipeline will process.
    SEL selSetPhase     = NSSelectorFromString(@"setPhase:");
    SEL selSetWindow    = NSSelectorFromString(@"setWindow:");
    SEL selSetView      = NSSelectorFromString(@"setView:");
    SEL selSetLocation  = NSSelectorFromString(@"_setLocationInWindow:resetPrevious:");
    SEL selSetTimestamp = NSSelectorFromString(@"setTimestamp:");
    SEL selSetTapCount  = NSSelectorFromString(@"setTapCount:");

    if (![touch respondsToSelector:selSetPhase] ||
        ![touch respondsToSelector:selSetLocation]) {
        return NO;
    }

    // _touchesEvent is the singleton UIEvent that UIKit reuses for all touch
    // delivery. No public API exists to create or obtain a UIEvent for touches.
    UIEvent *event = [[UIApplication sharedApplication] valueForKey:@"_touchesEvent"];
    if (!event) return NO;

    SEL selClear    = NSSelectorFromString(@"_clearTouches");
    SEL selAddTouch = NSSelectorFromString(@"_addTouch:forDelayedDelivery:");

    @try {
        NSTimeInterval now = [NSProcessInfo processInfo].systemUptime;
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(touch, selSetPhase, UITouchPhaseBegan);
        ((void (*)(id, SEL, id))objc_msgSend)(touch, selSetWindow, window);
        ((void (*)(id, SEL, id))objc_msgSend)(touch, selSetView, targetView);
        ((void (*)(id, SEL, CGPoint, BOOL))objc_msgSend)(touch, selSetLocation, windowPoint, YES);
        ((void (*)(id, SEL, NSTimeInterval))objc_msgSend)(touch, selSetTimestamp, now);
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(touch, selSetTapCount, (NSUInteger)1);

        if ([event respondsToSelector:selClear]) {
            ((void (*)(id, SEL))objc_msgSend)(event, selClear);
        }
        if ([event respondsToSelector:selAddTouch]) {
            ((void (*)(id, SEL, id, BOOL))objc_msgSend)(event, selAddTouch, touch, NO);
        }

        [[UIApplication sharedApplication] sendEvent:event];

        // 100ms between began and ended mimics a fast but realistic tap duration.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try {
                ((void (*)(id, SEL, NSInteger))objc_msgSend)(touch, selSetPhase, UITouchPhaseEnded);
                ((void (*)(id, SEL, NSTimeInterval))objc_msgSend)(touch, selSetTimestamp, [NSProcessInfo processInfo].systemUptime);
                if ([event respondsToSelector:selClear]) {
                    ((void (*)(id, SEL))objc_msgSend)(event, selClear);
                }
                if ([event respondsToSelector:selAddTouch]) {
                    ((void (*)(id, SEL, id, BOOL))objc_msgSend)(event, selAddTouch, touch, NO);
                }
                [[UIApplication sharedApplication] sendEvent:event];
            } @catch (NSException *e) {
                // Private API structure may change across iOS versions — fail silently
            }
        });

        return YES;
    } @catch (NSException *e) {
        return NO;
    }
}

+ (BOOL)tapAtPoint:(CGPoint)windowPoint inWindow:(UIWindow *)window {
    if (!window) return NO;

    // For dismiss testing: bypass ad SDK overlays, find the underlying WebKit view
    UIView *hitView = [self findWebContentViewAtPoint:windowPoint inView:window];
    if (!hitView) {
        hitView = [window hitTest:windowPoint withEvent:nil];
    }
    if (!hitView) return NO;

    return [self tapAtPoint:windowPoint onView:hitView inWindow:window];
}

@end
