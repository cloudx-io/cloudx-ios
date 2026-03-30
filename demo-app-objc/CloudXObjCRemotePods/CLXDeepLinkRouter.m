#import "CLXDeepLinkRouter.h"
#import "AdDemoTabViewController.h"
#import "BaseAdViewController.h"
#import "DemoAppLogger.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

static NSString *const kScheme = @"cloudx-demo";
static NSTimeInterval const kSDKInitTimeout = 30.0;
static NSTimeInterval const kAdLoadTimeout = 30.0;
static NSTimeInterval const kFullscreenDismissTimeout = 90.0;
static NSTimeInterval const kPollInterval = 1.0;
static NSUInteger const kMaxLoadRetries = 3;
static NSTimeInterval const kRetryDelay = 3.0;
static NSTimeInterval const kRevenueTimeout = 5.0;
static NSTimeInterval const kRevenuePollInterval = 0.5;

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

    NSInteger tabIndex = [self tabIndexForFormat:format];
    if (tabIndex < 0) {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Unknown format: %@", format]];
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

    NSInteger tabIndex = [self tabIndexForFormat:format];
    if (tabIndex < 0 || tabIndex >= (NSInteger)tabVC.viewControllers.count) {
        [[DemoAppLogger sharedInstance] logMessage:
            [NSString stringWithFormat:@"⚠️ test-all: Skipping %@ — invalid tab index", format]];
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
                    // Banner/MREC: revenue fires after auto-display on load
                    [self waitForRevenueCallback:adVC timeout:kRevenueTimeout format:format completion:^{
                        [self runFormat:formats atIndex:index + 1 tabVC:tabVC];
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

    // Wait briefly, then check if an alert appeared (meaning show failed)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self dismissAnyPresentedAlert]) {
            [[DemoAppLogger sharedInstance] logMessage:
                [NSString stringWithFormat:@"test-all: ⚠️ %@ show produced an alert (ad may not have been ready) — dismissed", format]];
            if (completion) completion();
            return;
        }

        // Fullscreen ad is likely displaying — wait for it to be dismissed
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

    UIViewController *rootVC = [self keyWindowFromConnectedScenes].rootViewController;
    UIViewController *presented = rootVC.presentedViewController;

    // No presented VC (or it's just an alert) means the fullscreen is gone
    if (!presented || [presented isKindOfClass:[UIAlertController class]]) {
        [self dismissAnyPresentedAlert];
        if (completion) completion();
        return;
    }

    if (elapsed >= timeout) {
        [[DemoAppLogger sharedInstance] logMessage:@"test-all: Fullscreen dismiss timed out — force-dismissing"];
        [rootVC dismissViewControllerAnimated:NO completion:^{
            if (completion) completion();
        }];
        return;
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

+ (NSInteger)tabIndexForFormat:(NSString *)format {
    static NSDictionary<NSString *, NSNumber *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"banner": @1,
            @"mrec": @4,
            @"interstitial": @2,
            @"rewarded": @3,
            @"rewarded-interstitial": @5,
        };
    });
    NSNumber *index = map[format];
    return index ? index.integerValue : -1;
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
