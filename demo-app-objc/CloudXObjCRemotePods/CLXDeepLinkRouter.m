#import "CLXDeepLinkRouter.h"
#import "AdDemoTabViewController.h"
#import "DemoAppLogger.h"

static NSString *const kScheme = @"cloudx-demo";

@implementation CLXDeepLinkRouter

+ (void)handleLaunchArguments {
    NSArray<NSString *> *args = [NSProcessInfo processInfo].arguments;

    NSString *format = nil;
    NSString *action = nil;
    NSString *command = nil;

    for (NSUInteger i = 0; i < args.count; i++) {
        if ([args[i] isEqualToString:@"-CLXTestFormat"] && i + 1 < args.count) {
            format = args[i + 1];
        } else if ([args[i] isEqualToString:@"-CLXTestAction"] && i + 1 < args.count) {
            action = args[i + 1];
        } else if ([args[i] isEqualToString:@"-CLXTestCommand"] && i + 1 < args.count) {
            command = args[i + 1];
        }
    }

    if (!format && !command) return;

    NSURL *url;
    if (command) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", kScheme, command]];
    } else {
        NSString *act = action ?: @"load";
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://test?format=%@&action=%@", kScheme, format, act]];
    }

    // Delay to ensure the UI hierarchy is fully established
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleURL:url];
    });
}

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
        [self handleTestAll];
        return YES;
    }

    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Unrecognized deep link host: %@", host]];
    return NO;
}

#pragma mark - Route Handlers

+ (void)handleInit:(NSURL *)url {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return;

    NSString *env = [self queryValueForKey:@"env" inURL:url] ?: @"production";
    [tabVC selectTabIndex:0];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UINavigationController *navVC = (UINavigationController *)tabVC.selectedViewController;
        UIViewController *initVC = navVC.viewControllers.firstObject;
        SEL selector = [self initSelectorForEnvironment:env];
        if ([initVC respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [initVC performSelector:selector];
#pragma clang diagnostic pop
        }
    });
}

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
        UINavigationController *navVC = (UINavigationController *)tabVC.selectedViewController;
        UIViewController *adVC = navVC.viewControllers.firstObject;

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

        if (isLoadShow) {
            SEL showSel = [self selectorForFormat:format action:@"show"];
            if (showSel && [adVC respondsToSelector:showSel]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(16.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [adVC performSelector:showSel];
#pragma clang diagnostic pop
                });
            }
        }
    });
}

+ (void)handleTestAll {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return;

    NSArray<NSDictionary *> *steps = @[
        @{@"format": @"banner", @"action": @"load"},
        @{@"format": @"mrec", @"action": @"load"},
        @{@"format": @"interstitial", @"action": @"load"},
        @{@"format": @"interstitial", @"action": @"show", @"delay": @16},
        @{@"format": @"rewarded", @"action": @"load"},
        @{@"format": @"rewarded", @"action": @"show", @"delay": @16},
    ];

    [self executeSteps:steps atIndex:0 tabVC:tabVC];
}

+ (void)executeSteps:(NSArray<NSDictionary *> *)steps atIndex:(NSUInteger)index tabVC:(AdDemoTabViewController *)tabVC {
    if (index >= steps.count) {
        [[DemoAppLogger sharedInstance] logMessage:@"test-all sequence complete"];
        return;
    }

    NSDictionary *step = steps[index];
    NSString *format = step[@"format"];
    NSString *action = step[@"action"];
    NSTimeInterval delay = [step[@"delay"] doubleValue] ?: 1.0;

    NSInteger tabIndex = [self tabIndexForFormat:format];
    if (tabIndex < 0 || tabIndex >= (NSInteger)tabVC.viewControllers.count) {
        [self executeSteps:steps atIndex:index + 1 tabVC:tabVC];
        return;
    }

    [tabVC selectTabIndex:tabIndex];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UINavigationController *navVC = (UINavigationController *)tabVC.selectedViewController;
        UIViewController *adVC = navVC.viewControllers.firstObject;
        SEL selector = [self selectorForFormat:format action:action];
        if (selector && [adVC respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [adVC performSelector:selector];
#pragma clang diagnostic pop
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self executeSteps:steps atIndex:index + 1 tabVC:tabVC];
        });
    });
}

#pragma mark - Tab Resolution

+ (NSInteger)tabIndexForFormat:(NSString *)format {
    static NSDictionary<NSString *, NSNumber *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"banner": @1,
            @"mrec": @4,
            @"interstitial": @2,
            @"rewarded": @3,
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
    return nil;
}

+ (SEL)initSelectorForEnvironment:(NSString *)env {
    if ([env isEqualToString:@"staging"]) return @selector(initializeWithStagingEnvironment);
    if ([env isEqualToString:@"dev"]) return @selector(initializeWithDevEnvironment);
    return @selector(initializeWithProductionEnvironment);
}

#pragma mark - Helpers

+ (nullable AdDemoTabViewController *)resolveTabViewController {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
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
