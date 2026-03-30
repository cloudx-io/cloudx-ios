#import "CLXDeepLinkRouter.h"
#import "AdDemoTabViewController.h"
#import "BaseAdViewController.h"
#import "DemoAppLogger.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>
#import <StoreKit/StoreKit.h>
#import <objc/message.h>

static NSString *const kScheme = @"cloudx-demo";
static NSTimeInterval const kSDKInitTimeout = 30.0;
static NSTimeInterval const kAdLoadTimeout = 30.0;
static NSTimeInterval const kFullscreenDismissTimeout = 90.0;
static NSTimeInterval const kPollInterval = 1.0;
static NSUInteger const kMaxLoadRetries = 3;
static NSTimeInterval const kRetryDelay = 3.0;
static NSTimeInterval const kRevenueTimeout = 5.0;
static NSTimeInterval const kRevenuePollInterval = 0.5;
static NSTimeInterval const kClickTimeout = 10.0;
static NSTimeInterval const kClickPollInterval = 0.5;
static NSTimeInterval const kClickOverlayDismissDelay = 2.0;

@implementation CLXDeepLinkRouter

#pragma mark - Launch Arguments

+ (void)handleLaunchArguments {
    NSArray<NSString *> *args = [NSProcessInfo processInfo].arguments;

    NSString *format = nil;
    NSString *action = nil;
    NSString *command = nil;
    NSString *env = nil;

    for (NSUInteger i = 0; i < args.count; i++) {
        if ([args[i] isEqualToString:@"-CLXTestFormat"] && i + 1 < args.count) {
            format = args[i + 1];
        } else if ([args[i] isEqualToString:@"-CLXTestAction"] && i + 1 < args.count) {
            action = args[i + 1];
        } else if ([args[i] isEqualToString:@"-CLXTestCommand"] && i + 1 < args.count) {
            command = args[i + 1];
        } else if ([args[i] isEqualToString:@"-CLXTestEnv"] && i + 1 < args.count) {
            env = args[i + 1];
        }
    }

    // Fallback: on iOS 26+, simctl launch writes -key value pairs to
    // NSUserDefaults volatile domain but not NSProcessInfo.arguments.
    if (!format && !command) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        command = [defaults stringForKey:@"CLXTestCommand"];
        format = [defaults stringForKey:@"CLXTestFormat"];
        action = [defaults stringForKey:@"CLXTestAction"];
        env = [defaults stringForKey:@"CLXTestEnv"];
    }

    if (!format && !command) return;

    NSURL *url;
    if (command) {
        NSString *envParam = env ? [NSString stringWithFormat:@"?env=%@", env] : @"";
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", kScheme, command, envParam]];
    } else {
        NSString *act = action ?: @"load";
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://test?format=%@&action=%@", kScheme, format, act]];
    }

    if (!url) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleURL:url];
    });
}

#pragma mark - URL Routing

+ (BOOL)handleURL:(NSURL *)url {
    if (![url.scheme isEqualToString:kScheme]) {
        return NO;
    }

    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Deep link received: %@", url.absoluteString]];

    NSString *host = url.host;

    if ([host isEqualToString:@"init"]) {
        [self handleInit:url];
        return YES;
    }
    if ([host isEqualToString:@"test"]) {
        [self handleTest:url];
        return YES;
    }
    if ([host isEqualToString:@"test-all"]) {
        NSString *env = [self queryValueForKey:@"env" inURL:url] ?: @"production";
        [self handleTestAllWithEnv:env];
        return YES;
    }

    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Unrecognized deep link host: %@", host]];
    return NO;
}

#pragma mark - Init Handler

+ (void)handleInit:(NSURL *)url {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return;

    NSString *env = [self queryValueForKey:@"env" inURL:url] ?: @"production";
    [tabVC selectTabIndex:0];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *initVC = [self vcAtTabIndex:0 inTabVC:tabVC];
        SEL selector = [self resolveInitSelectorForVC:initVC environment:env];
        if (selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [initVC performSelector:selector];
#pragma clang diagnostic pop
        }
    });
}

#pragma mark - Single Format Test

+ (void)handleTest:(NSURL *)url {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return;

    NSString *format = [self queryValueForKey:@"format" inURL:url];
    NSString *action = [self queryValueForKey:@"action" inURL:url] ?: @"load";

    if (!format) {
        [[DemoAppLogger sharedInstance] logMessage:@"Deep link missing 'format' parameter"];
        return;
    }

    NSInteger tabIndex = [self tabIndexForFormat:format inTabVC:tabVC];
    if (tabIndex < 0) {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Unknown or unavailable format: %@", format]];
        return;
    }

    [tabVC selectTabIndex:tabIndex];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *adVC = [self vcAtTabIndex:tabIndex inTabVC:tabVC];
        BOOL isLoadShow = [action isEqualToString:@"load-show"];
        NSString *effectiveAction = isLoadShow ? @"load" : action;

        SEL selector = [self selectorForFormat:format action:effectiveAction];
        if (selector && [adVC respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [adVC performSelector:selector];
#pragma clang diagnostic pop
        } else {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"VC does not respond to %@ for format=%@, action=%@",
                    NSStringFromSelector(selector), format, action]];
            return;
        }

        if (isLoadShow && [adVC conformsToProtocol:@protocol(AdStateManaging)]) {
            [self waitForLoadCompletion:(UIViewController<AdStateManaging> *)adVC
                                timeout:kAdLoadTimeout
                             completion:^(BOOL loaded) {
                if (loaded) {
                    SEL showSel = [self selectorForFormat:format action:@"show"];
                    if (showSel && [adVC respondsToSelector:showSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [adVC performSelector:showSel];
#pragma clang diagnostic pop
                    }
                } else {
                    [[DemoAppLogger sharedInstance] logMessage:
                        [NSString stringWithFormat:@"⚠️ Ad did not load within timeout for format: %@", format]];
                }
            }];
        }
    });
}

#pragma mark - Test All (Event-Driven)

+ (void)handleTestAllWithEnv:(NSString *)env {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return;

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all: Starting — init env=%@, then test all formats", env]];

    // Phase 1: Navigate to init tab and trigger SDK initialization
    [tabVC selectTabIndex:0];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *initVC = [self vcAtTabIndex:0 inTabVC:tabVC];
        SEL initSel = [self resolveInitSelectorForVC:initVC environment:env];

        if (!initSel) {
            [[DemoAppLogger sharedInstance] logMessage:@"test-all: Init VC does not respond to any init selector — aborting"];
            return;
        }

        // Observe SDK init notification
        __block id observer = nil;
        __block BOOL initCompleted = NO;

        observer = [[NSNotificationCenter defaultCenter]
            addObserverForName:@"cloudXSDKInitialized"
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
            initCompleted = YES;
            [[NSNotificationCenter defaultCenter] removeObserver:observer];

            [[DemoAppLogger sharedInstance] logMessage:@"test-all: SDK initialized — resolving ATT before tests"];
            [self resolveATTThenRunTestsWithTabVC:tabVC];
        }];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [initVC performSelector:initSel];
#pragma clang diagnostic pop

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSDKInitTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!initCompleted) {
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
                [[DemoAppLogger sharedInstance] logMessage:
                    [NSString stringWithFormat:@"⚠️ test-all: SDK init timed out after %.0fs — resolving ATT before tests", kSDKInitTimeout]];
                [self resolveATTThenRunTestsWithTabVC:tabVC];
            }
        });
    });
}

// ATT must be resolved before ad loading — ads without ATT authorization
// may receive no fill. Request authorization if still undetermined, then
// proceed to the test sequence regardless of the user's choice.
+ (void)resolveATTThenRunTestsWithTabVC:(AdDemoTabViewController *)tabVC {
    if (@available(iOS 14, *)) {
        ATTrackingManagerAuthorizationStatus status = ATTrackingManager.trackingAuthorizationStatus;
        if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
            [[DemoAppLogger sharedInstance] logMessage:@"test-all: ATT not determined — requesting authorization"];
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus newStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self logATTStatus];
                    [[DemoAppLogger sharedInstance] logMessage:@"test-all: ATT resolved — starting ad format tests"];
                    [self runTestSequenceWithTabVC:tabVC];
                });
            }];
            return;
        }
    }
    [self logATTStatus];
    [[DemoAppLogger sharedInstance] logMessage:@"test-all: ATT already resolved — starting ad format tests"];
    [self runTestSequenceWithTabVC:tabVC];
}

+ (void)logATTStatus {
    ATTrackingManagerAuthorizationStatus status = ATTrackingManager.trackingAuthorizationStatus;
    NSString *statusName;
    switch (status) {
        case ATTrackingManagerAuthorizationStatusAuthorized:     statusName = @"authorized";     break;
        case ATTrackingManagerAuthorizationStatusDenied:         statusName = @"denied";         break;
        case ATTrackingManagerAuthorizationStatusRestricted:     statusName = @"restricted";     break;
        case ATTrackingManagerAuthorizationStatusNotDetermined:  statusName = @"notDetermined";  break;
        default:                                                 statusName = @"unknown";        break;
    }
    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"ATT_STATUS: %@", statusName]];
}

+ (void)runTestSequenceWithTabVC:(AdDemoTabViewController *)tabVC {
    NSArray<NSDictionary *> *formats = @[
        @{@"format": @"banner",                 @"show": @NO},
        @{@"format": @"mrec",                   @"show": @NO},
        @{@"format": @"interstitial",           @"show": @YES},
        @{@"format": @"rewarded",               @"show": @YES},
        @{@"format": @"rewarded-interstitial",  @"show": @YES},
    ];

    [self runFormat:formats atIndex:0 tabVC:tabVC];
}

+ (void)runFormat:(NSArray<NSDictionary *> *)formats
          atIndex:(NSUInteger)index
            tabVC:(AdDemoTabViewController *)tabVC {

    if (index >= formats.count) {
        [[DemoAppLogger sharedInstance] logMessage:@"test-all sequence complete"];
        return;
    }

    NSDictionary *entry = formats[index];
    NSString *format = entry[@"format"];
    BOOL shouldShow = [entry[@"show"] boolValue];

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all [%lu/%lu]: Testing %@",
            (unsigned long)(index + 1), (unsigned long)formats.count, format]];

    NSString *dismissedAlert = [self dismissAlertReturningClassName];
    [self logUIState:dismissedAlert];

    NSInteger tabIndex = [self tabIndexForFormat:format inTabVC:tabVC];
    if (tabIndex < 0 || tabIndex >= (NSInteger)tabVC.viewControllers.count) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"⚠️ test-all: Skipping %@ — no matching tab in this app", format]];
        [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
        return;
    }

    [tabVC selectTabIndex:tabIndex];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *adVC = [self vcAtTabIndex:tabIndex inTabVC:tabVC];

        SEL loadSel = [self selectorForFormat:format action:@"load"];
        if (!loadSel || ![adVC respondsToSelector:loadSel]) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"⚠️ test-all: VC (%@) does not respond to %@ for %@",
                    NSStringFromClass([adVC class]),
                    loadSel ? NSStringFromSelector(loadSel) : @"(nil)",
                    format]];
            [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
            return;
        }

        [self loadAdWithRetries:kMaxLoadRetries
                         format:format
                      shouldShow:shouldShow
                          adVC:adVC
                        loadSel:loadSel
                        formats:formats
                        atIndex:index
                          tabVC:tabVC
                        attempt:1];
    });
}

+ (void)loadAdWithRetries:(NSUInteger)maxRetries
                   format:(NSString *)format
                shouldShow:(BOOL)shouldShow
                    adVC:(UIViewController *)adVC
                  loadSel:(SEL)loadSel
                  formats:(NSArray<NSDictionary *> *)formats
                  atIndex:(NSUInteger)index
                    tabVC:(AdDemoTabViewController *)tabVC
                  attempt:(NSUInteger)attempt {

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all: Loading %@ (attempt %lu/%lu)...",
            format, (unsigned long)attempt, (unsigned long)maxRetries]];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [adVC performSelector:loadSel];
#pragma clang diagnostic pop

    if ([adVC conformsToProtocol:@protocol(AdStateManaging)]) {
        [self waitForLoadCompletion:(UIViewController<AdStateManaging> *)adVC
                            timeout:kAdLoadTimeout
                         completion:^(BOOL loaded) {
            if (loaded) {
                [[DemoAppLogger sharedInstance] logMessage:
                    [NSString stringWithFormat:@"test-all: ✅ %@ loaded successfully (attempt %lu)", format, (unsigned long)attempt]];

                if (shouldShow) {
                    // Fullscreen: revenue fires on impression, so show first then verify revenue after dismissal
                    [self showAndWaitForDismissal:format adVC:adVC completion:^{
                        [self waitForRevenueCallback:adVC timeout:kRevenueTimeout format:format completion:^{
                            [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
                        }];
                    }];
                } else {
                    // Banner/MREC: revenue fires after auto-display on load, then click test.
                    // Delay 2s after revenue to avoid "premature click" rejection by ad SDKs.
                    [self waitForRevenueCallback:adVC timeout:kRevenueTimeout format:format completion:^{
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self performInAppClickOnAdVC:adVC format:format];
                            [self waitForClickCallback:adVC timeout:kClickTimeout format:format completion:^(BOOL clicked) {
                                if (clicked) {
                                    [self dismissClickOverlayWithCompletion:^{
                                        [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
                                    }];
                                } else {
                                    [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
                                }
                            }];
                        });
                    }];
                }
            } else if (attempt < maxRetries) {
                [[DemoAppLogger sharedInstance] logMessage:
                    [NSString stringWithFormat:@"test-all: ⚠️ %@ load failed (attempt %lu/%lu) — retrying in %.0fs...",
                        format, (unsigned long)attempt, (unsigned long)maxRetries, kRetryDelay]];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self loadAdWithRetries:maxRetries
                                     format:format
                                  shouldShow:shouldShow
                                      adVC:adVC
                                    loadSel:loadSel
                                    formats:formats
                                    atIndex:index
                                      tabVC:tabVC
                                    attempt:attempt + 1];
                });
            } else {
                [[DemoAppLogger sharedInstance] logMessage:
                    [NSString stringWithFormat:@"test-all: ❌ %@ failed after %lu attempts — moving on", format, (unsigned long)maxRetries]];

                [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
            }
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAdLoadTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
        });
    }
}

#pragma mark - Fullscreen Dismiss Detection
//
// Multi-tier dismiss strategy:
// All interaction happens IN-PROCESS via synthetic UITouch and JS injection.
// No external tools (cliclick, osascript) are used — the simulator does NOT need
// to be visible or frontmost. This enables parallel test execution on multiple
// simulators from different Cursor agents without window management.
//
// Tier escalation is based on ACTUAL failed attempts, not wall-clock time.
// This avoids skipping tiers when a close button appears late (e.g., after a
// 15-30s countdown). Each tier gets a fair chance before escalating.
//
// Tier 1: tapView: (UIControl sendActions / accessibilityActivate) on top candidate
// Tier 2: Synthetic UITouch on top candidate (reaches gesture recognizers)
// Tier 3: JS click injection in WKWebView at candidate coordinates
// Tier 4: JS blind corner taps (when no native candidates found — close button
//         is rendered entirely within the WKWebView)
// Force dismiss: programmatic dismissViewControllerAnimated: after exhausting tiers

static NSUInteger _dismissTapAttempts = 0;
static NSUInteger _dismissNoCandidatePolls = 0;

static NSInteger const kDismissCandidateScoreThreshold = 4;
static NSTimeInterval const kDismissInitialDelay = 5.0;
static NSUInteger const kTier2TapThreshold = 2;
static NSUInteger const kTier3TapThreshold = 5;
static NSUInteger const kForceDismissTapThreshold = 12;
static NSUInteger const kTier4NoCandidateThreshold = 5;
static NSTimeInterval const kTier4MinElapsed = 20.0;
static NSUInteger const kForceNoCandidateThreshold = 15;

+ (NSArray<UIView *> *)findDismissCandidatesInView:(UIView *)rootView {
    NSMutableArray<UIView *> *candidates = [NSMutableArray array];
    [self collectDismissCandidatesFromView:rootView into:candidates insideWebView:NO];

    [candidates sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        NSInteger scoreA = [self scoreDismissCandidate:a];
        NSInteger scoreB = [self scoreDismissCandidate:b];
        return scoreB > scoreA ? NSOrderedDescending :
               scoreB < scoreA ? NSOrderedAscending : NSOrderedSame;
    }];

    return [candidates copy];
}

+ (void)collectDismissCandidatesFromView:(UIView *)view
                                    into:(NSMutableArray<UIView *> *)candidates
                          insideWebView:(BOOL)insideWebView {
    if (view.hidden || view.alpha < 0.1 || !view.userInteractionEnabled) return;
    if (insideWebView || [view isKindOfClass:[WKWebView class]]) {
        for (UIView *subview in view.subviews) {
            [self collectDismissCandidatesFromView:subview into:candidates insideWebView:YES];
        }
        return;
    }

    NSInteger score = [self scoreDismissCandidate:view];
    if (score >= kDismissCandidateScoreThreshold) {
        [candidates addObject:view];
    }

    for (UIView *subview in view.subviews) {
        [self collectDismissCandidatesFromView:subview into:candidates insideWebView:NO];
    }
}

/// Heuristic scoring for likely close/dismiss buttons in fullscreen ad views.
/// Higher score = more likely to be a close button. Threshold: kDismissCandidateScoreThreshold.
///
/// Scoring logic:
/// - Small size (≤50x50) in a top corner = classic close button placement (+3 size, +3 position)
/// - Accessibility labels/titles containing "close", "skip", "x", ">>" = strong signal (+5)
/// - Non-dismiss elements (AdChoices, mute, info, learn more, install) = heavy penalty (-10)
/// - UIButton/UIControl or tap gesture recognizer = minor bonus (+1)
+ (NSInteger)scoreDismissCandidate:(UIView *)view {
    NSInteger score = 0;

    CGRect frameInWindow = [view convertRect:view.bounds toView:nil];
    CGFloat w = frameInWindow.size.width;
    CGFloat h = frameInWindow.size.height;

    if (w <= 50 && h <= 50 && w > 0 && h > 0) {
        score += 3;
    } else if (w <= 60 && h <= 60 && w > 0 && h > 0) {
        score += 2;
    }

    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    BOOL nearLeftEdge = frameInWindow.origin.x < 80;
    BOOL nearRightEdge = CGRectGetMaxX(frameInWindow) > screenWidth - 80;
    BOOL nearTop = frameInWindow.origin.y < 100;
    if ((nearLeftEdge || nearRightEdge) && nearTop) {
        score += 3;
    }

    NSString *label = view.accessibilityLabel.lowercaseString ?: @"";
    NSString *title = @"";
    if ([view isKindOfClass:[UIButton class]]) {
        title = [(UIButton *)view titleForState:UIControlStateNormal].lowercaseString ?: @"";
    }
    NSString *className = NSStringFromClass([view class]).lowercaseString;

    // Positive: close/skip/dismiss indicators
    if (label.length > 0) {
        if ([label containsString:@"close"] ||
            [label containsString:@"skip"] ||
            [label containsString:@"dismiss"] ||
            [label containsString:@"forward"] ||
            [label containsString:@"done"] ||
            [label isEqualToString:@"x"] ||
            [label isEqualToString:@">>"]) {
            score += 5;
        }
    }
    if ([title containsString:@"close"] ||
        [title containsString:@"skip"] ||
        [title containsString:@"×"] ||
        [title containsString:@"✕"] ||
        [title isEqualToString:@"x"] ||
        [title isEqualToString:@">>"]) {
        score += 5;
    }

    // Penalize non-dismiss interactive elements
    if ([label containsString:@"choice"] ||
        [label containsString:@"mute"] ||
        [label containsString:@"audio"] ||
        [label containsString:@"info"] ||
        [label containsString:@"report"] ||
        [label containsString:@"advertiser"] ||
        [label containsString:@"privacy"] ||
        [label containsString:@"learn more"] ||
        [label containsString:@"install"]) {
        score -= 10;
    }
    if ([className containsString:@"adchoice"] ||
        [className containsString:@"mute"] ||
        [className containsString:@"privacy"]) {
        score -= 10;
    }

    if ([view isKindOfClass:[UIButton class]] || [view isKindOfClass:[UIControl class]]) {
        score += 1;
    }

    for (UIGestureRecognizer *gr in view.gestureRecognizers) {
        if ([gr isKindOfClass:[UITapGestureRecognizer class]]) {
            score += 1;
            break;
        }
    }

    return score;
}

/// Attempts to programmatically activate a view using public APIs only.
/// Used by dismiss candidate tapping — synthetic UITouch (synthesizeTapAtPoint:)
/// handles the cases where these strategies are insufficient.
+ (BOOL)tapView:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        [(UIControl *)view sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }

    if ([view accessibilityActivate]) {
        return YES;
    }

    // Walk up the responder chain for a UIControl ancestor
    UIResponder *responder = view.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[UIControl class]]) {
            [(UIControl *)responder sendActionsForControlEvents:UIControlEventTouchUpInside];
            return YES;
        }
        responder = responder.nextResponder;
    }

    return NO;
}

/// Traverses the view hierarchy to find the deepest WebKit-related subview.
/// See CLXSyntheticTouch.h for rationale on private API usage.
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

/// Dispatches a synthetic UITouch began+ended sequence targeting a specific view.
/// Uses UIKit private APIs (_touchesEvent, _setLocationInWindow:) because there is
/// no public API to inject touch events into a running app. See CLXSyntheticTouch.h.
+ (BOOL)synthesizeTapAtPoint:(CGPoint)windowPoint onView:(UIView *)targetView inWindow:(UIWindow *)window {
    if (!window || !targetView) return NO;

    UITouch *touch = [[UITouch alloc] init];

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

    UIEvent *event = [[UIApplication sharedApplication] valueForKey:@"_touchesEvent"];
    if (!event) return NO;

    SEL selClear   = NSSelectorFromString(@"_clearTouches");
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
                // Private API structure changed — silent fallback
            }
        });

        return YES;
    } @catch (NSException *e) {
        return NO;
    }
}

/// Finds the deepest WebKit view and dispatches a synthetic tap targeting it.
/// Used for fullscreen dismiss where we need to bypass ad SDK overlays.
+ (BOOL)synthesizeTapAtPoint:(CGPoint)windowPoint inWindow:(UIWindow *)window {
    if (!window) return NO;

    UIView *hitView = [self findWebContentViewAtPoint:windowPoint inView:window];
    if (!hitView) {
        hitView = [window hitTest:windowPoint withEvent:nil];
    }
    if (!hitView) return NO;

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all: SyntheticTouch hitView=%@ frame=%@",
            NSStringFromClass([hitView class]),
            NSStringFromCGRect([hitView convertRect:hitView.bounds toView:nil])]];

    return [self synthesizeTapAtPoint:windowPoint onView:hitView inWindow:window];
}

/// Taps a specific point in a WKWebView by injecting JavaScript touch + click events.
/// @param point A point in the window (device) coordinate space.
+ (void)tapPointInWebView:(WKWebView *)webView atDevicePoint:(CGPoint)point {
    CGPoint localPoint = [webView convertPoint:point fromView:nil];
    [self tapPointInWebViewLocal:webView atPoint:localPoint];
}

/// Taps a specific point in a WKWebView using local (webView) coordinates.
+ (void)tapPointInWebViewLocal:(WKWebView *)webView atPoint:(CGPoint)point {
    NSString *js = [NSString stringWithFormat:
        @"(function(){"
         "var x=%f,y=%f;"
         "var el=document.elementFromPoint(x,y);"
         "if(!el) return 'none';"
         "try{"
           "var t=new Touch({identifier:Date.now(),target:el,clientX:x,clientY:y});"
           "el.dispatchEvent(new TouchEvent('touchstart',{bubbles:true,cancelable:true,touches:[t],targetTouches:[t],changedTouches:[t]}));"
           "el.dispatchEvent(new TouchEvent('touchend',{bubbles:true,cancelable:true,touches:[],targetTouches:[],changedTouches:[t]}));"
         "}catch(e){}"
         "el.click();"
         "return el.tagName;"
        "})()", point.x, point.y];
    [webView evaluateJavaScript:js completionHandler:^(id result, NSError *error) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: WKWebView JS click at (%.0f,%.0f) → %@",
                point.x, point.y, result ?: @"error"]];
    }];
}

+ (BOOL)tapTopDismissCandidate:(NSArray<UIView *> *)candidates {
    if (candidates.count == 0) return NO;

    UIView *top = candidates.firstObject;
    BOOL tapped = [self tapView:top];
    if (tapped) {
        CGRect frame = [top convertRect:top.bounds toView:nil];
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: Dismiss Tier 1 — tapped candidate (%@) at (%.0f, %.0f) score=%ld",
                NSStringFromClass([top class]),
                CGRectGetMidX(frame), CGRectGetMidY(frame),
                (long)[self scoreDismissCandidate:top]]];
    }
    return tapped;
}

+ (BOOL)tapAllDismissCandidates:(NSArray<UIView *> *)candidates {
    BOOL anyTapped = NO;
    for (UIView *candidate in candidates) {
        if ([self tapView:candidate]) {
            CGRect frame = [candidate convertRect:candidate.bounds toView:nil];
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: Dismiss Tier 2 — tapped candidate (%@) at (%.0f, %.0f)",
                    NSStringFromClass([candidate class]),
                    CGRectGetMidX(frame), CGRectGetMidY(frame)]];
            anyTapped = YES;
        }
    }
    return anyTapped;
}

#pragma mark - Show + Wait for Fullscreen Dismissal

+ (void)showAndWaitForDismissal:(NSString *)format
                           adVC:(UIViewController *)adVC
                     completion:(void (^)(void))completion {

    SEL showSel = [self selectorForFormat:format action:@"show"];
    if (!showSel || ![adVC respondsToSelector:showSel]) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: VC does not respond to show for %@", format]];
        if (completion) completion();
        return;
    }

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all: Showing %@...", format]];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [adVC performSelector:showSel];
#pragma clang diagnostic pop

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self dismissAnyPresentedAlert]) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: ⚠️ %@ show produced an alert (ad may not have been ready) — dismissed", format]];
            if (completion) completion();
            return;
        }

        [self waitForFullscreenDismissalElapsed:0
                                       timeout:kFullscreenDismissTimeout
                                    completion:^{
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: %@ fullscreen dismissed", format]];
            if (completion) completion();
        }];
    });
}

+ (void)waitForFullscreenDismissalElapsed:(NSTimeInterval)elapsed
                                  timeout:(NSTimeInterval)timeout
                               completion:(void (^)(void))completion {

    if (elapsed == 0) {
        _dismissTapAttempts = 0;
        _dismissNoCandidatePolls = 0;
    }

    UIViewController *rootVC = [self keyWindowFromConnectedScenes].rootViewController;
    UIViewController *presented = rootVC.presentedViewController;

    if (!presented || [presented isKindOfClass:[UIAlertController class]]) {
        [self dismissAnyPresentedAlert];
        if (completion) completion();
        return;
    }

    // Dismiss nested overlays (e.g., AdChoices, privacy sheets) that appear
    // on top of the fullscreen ad and block interaction with the close button.
    UIViewController *nestedPresented = presented.presentedViewController;
    if (nestedPresented && ![nestedPresented isKindOfClass:[UIAlertController class]]) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: Dismissing nested overlay (%@) on top of fullscreen ad",
                NSStringFromClass([nestedPresented class])]];
        [presented dismissViewControllerAnimated:NO completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self waitForFullscreenDismissalElapsed:elapsed + 0.5 timeout:timeout completion:completion];
            });
        }];
        return;
    }

    if (elapsed >= timeout) {
        [[DemoAppLogger sharedInstance] logMessage:@"test-all: Fullscreen dismiss timed out — force-dismissing"];
        [rootVC dismissViewControllerAnimated:NO completion:^{
            if (completion) completion();
        }];
        return;
    }

    // Active dismiss detection starts after initial delay
    if (elapsed >= kDismissInitialDelay) {
        NSArray<UIView *> *candidates = [self findDismissCandidatesInView:presented.view];

        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: Dismiss scan elapsed=%.0f candidates=%lu tapAttempts=%lu noCandidatePolls=%lu presented=%@",
                elapsed, (unsigned long)candidates.count, (unsigned long)_dismissTapAttempts,
                (unsigned long)_dismissNoCandidatePolls, NSStringFromClass([presented class])]];

        if (candidates.count > 0) {
            if (_dismissTapAttempts >= kForceDismissTapThreshold) {
                [[DemoAppLogger sharedInstance] logMessage:
                    [NSString stringWithFormat:@"test-all: Force-dismiss after %lu failed tap attempts", (unsigned long)_dismissTapAttempts]];
                [rootVC dismissViewControllerAnimated:NO completion:^{
                    if (completion) completion();
                }];
                return;
            } else if (_dismissTapAttempts < kTier2TapThreshold) {
                [self tapTopDismissCandidate:candidates];
            } else if (_dismissTapAttempts < kTier3TapThreshold) {
                // Tier 2: Synthesize a real UITouch on the top candidate
                UIView *top = candidates.firstObject;
                CGRect topFrame = [top convertRect:top.bounds toView:nil];
                CGPoint topCenter = CGPointMake(CGRectGetMidX(topFrame), CGRectGetMidY(topFrame));
                UIWindow *win = [self keyWindowFromConnectedScenes];
                if (win && [self synthesizeTapAtPoint:topCenter inWindow:win]) {
                    [[DemoAppLogger sharedInstance] logMessage:
                        [NSString stringWithFormat:@"test-all: Dismiss Tier 2 — synthetic UITouch at (%.0f,%.0f)",
                            topCenter.x, topCenter.y]];
                } else {
                    [self tapAllDismissCandidates:candidates];
                }
            } else {
                // Tier 3: Try JS click on top candidate's coordinates in WKWebView
                UIView *top = candidates.firstObject;
                CGRect frame = [top convertRect:top.bounds toView:nil];
                CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
                WKWebView *webView = [self findWebViewInView:presented.view];
                if (webView) {
                    [self tapPointInWebView:webView atDevicePoint:center];
                    [[DemoAppLogger sharedInstance] logMessage:
                        @"test-all: Dismiss Tier 3 — JS click on WKWebView at candidate coords"];
                } else {
                    [self tapAllDismissCandidates:candidates];
                    [[DemoAppLogger sharedInstance] logMessage:
                        @"test-all: Dismiss Tier 3 — re-tapping all candidates (no WKWebView found)"];
                }
            }
            _dismissTapAttempts++;
        } else {
            _dismissNoCandidatePolls++;
            if (_dismissNoCandidatePolls >= kForceNoCandidateThreshold) {
                [[DemoAppLogger sharedInstance] logMessage:
                    [NSString stringWithFormat:@"test-all: Force-dismiss after %lu no-candidate polls",
                        (unsigned long)_dismissNoCandidatePolls]];
                [rootVC dismissViewControllerAnimated:NO completion:^{
                    if (completion) completion();
                }];
                return;
            } else if (_dismissNoCandidatePolls >= kTier4NoCandidateThreshold && elapsed >= kTier4MinElapsed) {
                WKWebView *webView = [self findWebViewInView:presented.view];
                if (webView) {
                    // Use the WKWebView's own bounds for corner coordinates
                    CGFloat wvW = webView.bounds.size.width;
                    [self tapPointInWebViewLocal:webView atPoint:CGPointMake(wvW - 25, 25)];
                    [self tapPointInWebViewLocal:webView atPoint:CGPointMake(25, 25)];
                    [self tapPointInWebViewLocal:webView atPoint:CGPointMake(wvW - 25, 55)];
                    [self tapPointInWebViewLocal:webView atPoint:CGPointMake(25, 55)];
                    [[DemoAppLogger sharedInstance] logMessage:
                        @"test-all: Dismiss Tier 4 — JS blind corner taps in WKWebView"];
                } else {
                    [[DemoAppLogger sharedInstance] logMessage:
                        @"test-all: Dismiss Tier 4 — no candidates, no WKWebView — force dismiss"];
                    [rootVC dismissViewControllerAnimated:NO completion:^{
                        if (completion) completion();
                    }];
                    return;
                }
            }
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self waitForFullscreenDismissalElapsed:elapsed + 2.0 timeout:timeout completion:completion];
    });
}

#pragma mark - Polling: Wait for Ad Load

+ (void)waitForLoadCompletion:(UIViewController<AdStateManaging> *)adVC
                      timeout:(NSTimeInterval)timeout
                   completion:(void (^)(BOOL loaded))completion {
    [self pollLoadState:adVC elapsed:0 timeout:timeout completion:completion];
}

+ (void)pollLoadState:(UIViewController<AdStateManaging> *)adVC
              elapsed:(NSTimeInterval)elapsed
              timeout:(NSTimeInterval)timeout
           completion:(void (^)(BOOL loaded))completion {

    if (!adVC.isLoading && elapsed > 0) {
        BOOL loaded = NO;
        if ([adVC isKindOfClass:[BaseAdViewController class]]) {
            BaseAdViewController *baseVC = (BaseAdViewController *)adVC;
            NSString *text = baseVC.statusLabel.text ?: @"";
            BOOL hasFailureIndicator = [text containsString:@"Failed"] ||
                                       [text containsString:@"Error"] ||
                                       [text containsString:@"No Ad"] ||
                                       [text containsString:@"No Fill"];
            // Green indicator = success, red = failure
            BOOL isGreenIndicator = [baseVC.statusIndicator.backgroundColor isEqual:[UIColor systemGreenColor]];
            loaded = isGreenIndicator && !hasFailureIndicator;
        }
        if (completion) completion(loaded);
        return;
    }

    if (elapsed >= timeout) {
        if (completion) completion(NO);
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPollInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Clear any app-level alerts (e.g., ad load failure dialogs) that
        // appeared during loading so they don't block the next poll/action.
        [self dismissAnyPresentedAlert];
        [self pollLoadState:adVC elapsed:elapsed + kPollInterval timeout:timeout completion:completion];
    });
}

#pragma mark - Polling: Wait for Revenue Callback

+ (void)waitForRevenueCallback:(UIViewController *)adVC
                       timeout:(NSTimeInterval)timeout
                        format:(NSString *)format
                    completion:(void (^)(void))completion {
    [self pollRevenueState:adVC elapsed:0 timeout:timeout format:format completion:completion];
}

+ (void)pollRevenueState:(UIViewController *)adVC
                 elapsed:(NSTimeInterval)elapsed
                 timeout:(NSTimeInterval)timeout
                  format:(NSString *)format
              completion:(void (^)(void))completion {

    if ([adVC conformsToProtocol:@protocol(AdStateManaging)]) {
        UIViewController<AdStateManaging> *stateVC = (UIViewController<AdStateManaging> *)adVC;
        if (stateVC.receivedCallbacks & AdCallbackEventRevenueReceived) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: ✅ %@ — didPayRevenueForAd received (%.1fs)", format, elapsed]];
            if (completion) completion();
            return;
        }
    }

    if (elapsed >= timeout) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: ⚠️ %@ — didPayRevenueForAd not received within %.0fs", format, timeout]];
        if (completion) completion();
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRevenuePollInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pollRevenueState:adVC elapsed:elapsed + kRevenuePollInterval timeout:timeout format:format completion:completion];
    });
}

#pragma mark - Click Testing: Log Target & Poll
//
// Multi-strategy click approach:
// Different ad SDKs track clicks differently. Some use transparent UIView overlays
// (returned by hitTest:), others use WKWebView navigation interception, and others
// use UIControl/gesture recognizer targets. We fire ALL strategies on every click
// rather than exiting after the first "success" — a strategy can dispatch without
// error but still not trigger the SDK's click handler.
//
// Strategy 1 (hitTest target) is closest to a real user tap and works for most SDKs.
// Strategy 2 (WebKit content view) bypasses overlays and reaches WKWebView GR targets.
// Strategy 3 (JS injection) works when the ad is a web creative with click handlers.
// Strategy 4 (UIControl/accessibility) is a fallback for native-rendered ads.

+ (void)performInAppClickOnAdVC:(UIViewController *)adVC format:(NSString *)format {
    if (![adVC conformsToProtocol:@protocol(AdStateManaging)]) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: ⚠️ %@ VC does not conform to AdStateManaging — skipping click", format]];
        return;
    }

    UIView *adView = nil;
    if ([adVC respondsToSelector:@selector(adViewForClickTesting)]) {
        adView = [(id<AdStateManaging>)adVC adViewForClickTesting];
    }
    if (!adView) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: No ad view available for click testing on %@", format]];
        return;
    }

    CGRect frame = [adView convertRect:adView.bounds toView:nil];
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all: Clicking %@ ad in-app at (%.0f,%.0f) size=%.0fx%.0f",
            format, center.x, center.y, frame.size.width, frame.size.height]];

    UIWindow *window = adView.window;

    // Strategy 1: Synthetic UITouch on the system hitTest target.
    // hitTest: returns the topmost view — often the ad SDK's click-tracking
    // overlay. Tapping this view is closest to a real user tap.
    if (window) {
        UIView *hitTarget = [window hitTest:center withEvent:nil];
        if (hitTarget) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: %@ click — hitTest target: %@ frame=%@",
                    format, NSStringFromClass([hitTarget class]),
                    NSStringFromCGRect([hitTarget convertRect:hitTarget.bounds toView:nil])]];
            [self synthesizeTapAtPoint:center onView:hitTarget inWindow:window];
        }
    }

    // Strategy 2: Synthetic UITouch on the deepest WebKit content view.
    // Bypasses ad SDK overlays — reaches WKContentView/WKChildScrollView
    // where WebKit's gesture recognizers process taps into navigations.
    if (window) {
        [self synthesizeTapAtPoint:center inWindow:window];
    }

    // Strategy 3: JS click injection on any WKWebView inside the ad view.
    WKWebView *webView = [self findWebViewInView:adView];
    if (webView) {
        [self tapPointInWebView:webView atDevicePoint:center];
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: %@ click — JS injection in %@",
                format, NSStringFromClass([webView class])]];
    }

    // Strategy 4: UIControl sendActions / accessibility
    UIView *tappable = [self findFirstTappableSubview:adView];
    if (tappable && [self tapView:tappable]) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: %@ click — tappable subview (%@)",
                format, NSStringFromClass([tappable class])]];
    } else if ([adView accessibilityActivate]) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: %@ click — accessibilityActivate", format]];
    }

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"test-all: %@ click — all strategies dispatched", format]];
}

+ (nullable UIView *)findFirstTappableSubview:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if (subview.hidden || subview.alpha < 0.1 || !subview.userInteractionEnabled) continue;
        if ([subview isKindOfClass:[UIControl class]]) return subview;
        if (subview.gestureRecognizers.count > 0) return subview;
        UIView *found = [self findFirstTappableSubview:subview];
        if (found) return found;
    }
    return nil;
}

+ (nullable WKWebView *)findWebViewInView:(UIView *)view {
    if ([view isKindOfClass:[WKWebView class]]) return (WKWebView *)view;
    for (UIView *subview in view.subviews) {
        WKWebView *found = [self findWebViewInView:subview];
        if (found) return found;
    }
    return nil;
}

+ (void)waitForClickCallback:(UIViewController *)adVC
                     timeout:(NSTimeInterval)timeout
                      format:(NSString *)format
                  completion:(void (^)(BOOL clicked))completion {
    [self pollClickState:adVC elapsed:0 timeout:timeout format:format completion:completion];
}

+ (void)pollClickState:(UIViewController *)adVC
               elapsed:(NSTimeInterval)elapsed
               timeout:(NSTimeInterval)timeout
                format:(NSString *)format
            completion:(void (^)(BOOL clicked))completion {

    if ([adVC conformsToProtocol:@protocol(AdStateManaging)]) {
        UIViewController<AdStateManaging> *stateVC = (UIViewController<AdStateManaging> *)adVC;
        if (stateVC.receivedCallbacks & AdCallbackEventClicked) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: ✅ %@ — didClickAd received (%.1fs)", format, elapsed]];
            if (completion) completion(YES);
            return;
        }
    }

    if (elapsed >= timeout) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: ⚠️ %@ — didClickAd not received within %.0fs", format, timeout]];
        if (completion) completion(NO);
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kClickPollInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pollClickState:adVC elapsed:elapsed + kClickPollInterval timeout:timeout format:format completion:completion];
    });
}

/// Dismisses post-click overlays (SFSafariViewController, SKStoreProductViewController)
/// that ad SDKs present after a click. Polls because the app may be in the background
/// (click opened Safari or App Store) — dispatch_after still fires but UIKit state
/// is frozen until the app returns to foreground. The test-runner.sh re-foregrounds
/// the app by terminating Safari/App Store after detecting a click event in the logs.
+ (void)dismissClickOverlayWithCompletion:(void (^)(void))completion {
    [self pollDismissClickOverlay:0 completion:completion];
}

+ (void)pollDismissClickOverlay:(NSTimeInterval)elapsed completion:(void (^)(void))completion {
    static NSTimeInterval const kMaxWait = 10.0;
    static NSTimeInterval const kPollInterval = 1.0;

    if (elapsed >= kMaxWait) {
        [[DemoAppLogger sharedInstance] logMessage:@"test-all: Click overlay dismiss — timed out, continuing"];
        if (completion) completion();
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPollInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // If the app is in the background (click opened external browser), keep polling
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            [[DemoAppLogger sharedInstance] logMessage:@"test-all: Click overlay — app in background, waiting..."];
            [self pollDismissClickOverlay:elapsed + kPollInterval completion:completion];
            return;
        }

        UIViewController *rootVC = [self keyWindowFromConnectedScenes].rootViewController;
        UIViewController *presented = rootVC.presentedViewController;

        if ([presented isKindOfClass:[SFSafariViewController class]] ||
            [presented isKindOfClass:[SKStoreProductViewController class]]) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: Dismissing click overlay (%@)",
                    NSStringFromClass([presented class])]];
            [rootVC dismissViewControllerAnimated:NO completion:^{
                if (completion) completion();
            }];
            return;
        }

        if (presented && ![presented isKindOfClass:[UIAlertController class]] &&
            ![presented isKindOfClass:[UITabBarController class]]) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: Dismissing unknown click overlay (%@)",
                    NSStringFromClass([presented class])]];
            [rootVC dismissViewControllerAnimated:NO completion:^{
                if (completion) completion();
            }];
            return;
        }

        if (completion) completion();
    });
}

#pragma mark - UI State Logging

+ (void)logUIState:(nullable NSString *)dismissedClassName {
    UIViewController *rootVC = [self keyWindowFromConnectedScenes].rootViewController;
    UIViewController *presented = rootVC.presentedViewController;

    NSString *presentedInfo = presented
        ? NSStringFromClass([presented class])
        : @"none";

    if (dismissedClassName) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: UI state — dismissed %@, now presented: %@",
                dismissedClassName, presentedInfo]];
    } else {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"test-all: UI state — presented: %@", presentedInfo]];
    }
}

#pragma mark - Alert Dismissal

+ (BOOL)dismissAnyPresentedAlert {
    return [self dismissAlertReturningClassName] != nil;
}

/// Dismisses only UIAlertController instances. Safe to call at any time —
/// will never dismiss fullscreen ads, Safari views, or other legitimate VCs.
+ (nullable NSString *)dismissAlertReturningClassName {
    UIViewController *rootVC = [self keyWindowFromConnectedScenes].rootViewController;
    return [self dismissAlertFromViewController:rootVC];
}

+ (nullable NSString *)dismissAlertFromViewController:(UIViewController *)vc {
    if (!vc) return nil;

    UIViewController *presented = vc.presentedViewController;
    if ([presented isKindOfClass:[UIAlertController class]]) {
        NSString *title = ((UIAlertController *)presented).title ?: @"(untitled)";
        [presented dismissViewControllerAnimated:NO completion:nil];
        return [NSString stringWithFormat:@"UIAlertController(%@)", title];
    }

    if (presented) {
        return [self dismissAlertFromViewController:presented];
    }

    if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self dismissAlertFromViewController:((UITabBarController *)vc).selectedViewController];
    }
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self dismissAlertFromViewController:((UINavigationController *)vc).topViewController];
    }

    return nil;
}

#pragma mark - Tab & VC Resolution

// Scans the tab bar's viewControllers array and matches by VC class name
// rather than hardcoded indices, so the router works regardless of which
// formats an app includes or how its tabs are ordered.
+ (NSInteger)tabIndexForFormat:(NSString *)format inTabVC:(AdDemoTabViewController *)tabVC {
    static NSDictionary<NSString *, NSString *> *classNameMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classNameMap = @{
            @"banner":                 @"BannerViewController",
            @"mrec":                   @"MRECViewController",
            @"interstitial":           @"InterstitialViewController",
            @"rewarded":               @"RewardedViewController",
            @"rewarded-interstitial":  @"RewardedInterstitialViewController",
        };
    });

    NSString *targetClassName = classNameMap[format];
    if (!targetClassName) return -1;

    NSArray<UIViewController *> *vcs = tabVC.viewControllers;
    for (NSUInteger i = 0; i < vcs.count; i++) {
        UIViewController *vc = vcs[i];
        UIViewController *contentVC = vc;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            contentVC = ((UINavigationController *)vc).viewControllers.firstObject;
        }
        if (!contentVC) continue;
        if ([NSStringFromClass([contentVC class]) isEqualToString:targetClassName]) {
            return (NSInteger)i;
        }
    }

    [[DemoAppLogger sharedInstance] logMessage:
        [NSString stringWithFormat:@"tabIndexForFormat: No tab found for '%@' (expected VC class: %@)", format, targetClassName]];
    return -1;
}

+ (SEL)selectorForFormat:(NSString *)format action:(NSString *)action {
    BOOL isShow = [action isEqualToString:@"show"];

    if ([format isEqualToString:@"banner"]) {
        return @selector(loadBannerAd);
    }
    if ([format isEqualToString:@"mrec"]) {
        return @selector(loadMRECAd);
    }
    if ([format isEqualToString:@"interstitial"]) {
        return isShow ? @selector(showInterstitialAd) : @selector(loadInterstitialAd);
    }
    if ([format isEqualToString:@"rewarded"]) {
        return isShow ? @selector(showRewardedAd) : @selector(loadRewardedAd);
    }
    if ([format isEqualToString:@"rewarded-interstitial"]) {
        return isShow ? @selector(showRewardedInterstitialAd) : @selector(loadRewardedInterstitialAd);
    }
    return nil;
}

+ (SEL)initSelectorForEnvironment:(NSString *)env {
    if ([env isEqualToString:@"local"]) return @selector(initializeWithLocalEnvironment);
    if ([env isEqualToString:@"staging"]) return @selector(initializeWithStagingEnvironment);
    if ([env isEqualToString:@"dev"]) return @selector(initializeWithDevEnvironment);
    return @selector(initializeWithProductionEnvironment);
}

// Returns the best init selector the VC responds to: environment-specific first,
// then generic initializeSDK as fallback for apps with a single init button.
+ (nullable SEL)resolveInitSelectorForVC:(UIViewController *)vc environment:(NSString *)env {
    SEL envSel = [self initSelectorForEnvironment:env];
    if ([vc respondsToSelector:envSel]) return envSel;
    SEL genericSel = @selector(initializeSDK);
    if ([vc respondsToSelector:genericSel]) return genericSel;
    return nil;
}

+ (nullable UIViewController *)vcAtTabIndex:(NSInteger)tabIndex inTabVC:(AdDemoTabViewController *)tabVC {
    if (tabIndex < 0 || tabIndex >= (NSInteger)tabVC.viewControllers.count) return nil;

    // Try direct array access first — works for non-More tabs.
    UIViewController *vc = tabVC.viewControllers[tabIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UIViewController *root = ((UINavigationController *)vc).viewControllers.firstObject;
        if (root) return root;
    } else if (vc) {
        return vc;
    }

    // Fallback for "More" tab items: the system may move the content VC from
    // the original nav controller to moreNavigationController, leaving the
    // original empty. Resolve from the moreNavigationController stack instead.
    if (tabVC.selectedIndex == (NSUInteger)tabIndex) {
        UIViewController *top = tabVC.moreNavigationController.topViewController;
        if ([top isKindOfClass:[UINavigationController class]]) {
            UIViewController *root = ((UINavigationController *)top).viewControllers.firstObject;
            if (root) return root;
        }
        if (top) return top;
    }

    return nil;
}

+ (nullable UIWindow *)keyWindowFromConnectedScenes {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return nil;
}

+ (nullable AdDemoTabViewController *)resolveTabViewController {
    UIWindow *window = [self keyWindowFromConnectedScenes];
    UIViewController *rootVC = window.rootViewController;

    if ([rootVC isKindOfClass:[AdDemoTabViewController class]]) {
        return (AdDemoTabViewController *)rootVC;
    }
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        UIViewController *topVC = ((UINavigationController *)rootVC).topViewController;
        if ([topVC isKindOfClass:[AdDemoTabViewController class]]) {
            return (AdDemoTabViewController *)topVC;
        }
    }

    [[DemoAppLogger sharedInstance] logMessage:@"Could not resolve AdDemoTabViewController for deep link"];
    return nil;
}

+ (nullable NSString *)queryValueForKey:(NSString *)key inURL:(NSURL *)url {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:key]) {
            return item.value;
        }
    }
    return nil;
}

@end
