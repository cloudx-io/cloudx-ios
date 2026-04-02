#import "CLXDeepLinkRouter.h"

#if __has_include(<CloudXTestHarness/CLXTestHarness.h>)
#import "AdDemoTabViewController.h"
#import "BaseAdViewController.h"
#import "DemoAppLogger.h"
#import <CloudXTestHarness/CLXTestHarness.h>

static NSTimeInterval const kSDKInitTimeout = 30.0;

/// Format string → content VC class name mapping.
/// Matches the VC classes used in this demo app's storyboard/tab bar.
static NSDictionary<NSString *, NSString *> *classNameMap(void) {
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"banner":                 @"BannerViewController",
            @"mrec":                   @"MRECViewController",
            @"interstitial":           @"InterstitialViewController",
            @"rewarded":               @"RewardedViewController",
        };
    });
    return map;
}

#pragma mark - CLXTestHarnessApp Adapter

@interface CLXDeepLinkRouterAdapter : NSObject <CLXTestHarnessApp>
@end

@implementation CLXDeepLinkRouterAdapter

#pragma mark - Navigation

- (nullable UIViewController *)navigateToFormat:(NSString *)format {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return nil;

    NSInteger tabIndex = [self tabIndexForFormat:format inTabVC:tabVC];
    if (tabIndex < 0) return nil;

    [tabVC selectTabIndex:tabIndex];
    return [self vcAtTabIndex:tabIndex inTabVC:tabVC];
}

- (nullable UIViewController *)navigateToInit {
    AdDemoTabViewController *tabVC = [self resolveTabViewController];
    if (!tabVC) return nil;
    [tabVC selectTabIndex:0];
    return [self vcAtTabIndex:0 inTabVC:tabVC];
}

#pragma mark - Format Configuration

- (NSArray<NSString *> *)supportedFormats {
    return @[@"banner", @"mrec", @"interstitial", @"rewarded"];
}

- (BOOL)isFullscreenFormat:(NSString *)format {
    return [format isEqualToString:@"interstitial"] ||
           [format isEqualToString:@"rewarded"];
}

- (nullable SEL)loadSelectorForFormat:(NSString *)format {
    if ([format isEqualToString:@"banner"])                return @selector(loadBannerAd);
    if ([format isEqualToString:@"mrec"])                  return @selector(loadMRECAd);
    if ([format isEqualToString:@"interstitial"])           return @selector(loadInterstitialAd);
    if ([format isEqualToString:@"rewarded"])               return @selector(loadRewardedAd);
    return nil;
}

- (nullable SEL)showSelectorForFormat:(NSString *)format {
    if ([format isEqualToString:@"interstitial"])           return @selector(showInterstitialAd);
    if ([format isEqualToString:@"rewarded"])               return @selector(showRewardedAd);
    return nil;
}

#pragma mark - Ad State

- (BOOL)hasReceivedCallback:(CLXTestCallback)event forVC:(UIViewController *)vc {
    if (![vc conformsToProtocol:@protocol(AdStateManaging)]) return NO;
    UIViewController<AdStateManaging> *stateVC = (UIViewController<AdStateManaging> *)vc;

    // CLXTestCallback bit positions match AdCallbackEvent bit positions
    return (stateVC.receivedCallbacks & (AdCallbackEvent)event) != 0;
}

- (BOOL)isLoadingForVC:(UIViewController *)vc {
    if (![vc conformsToProtocol:@protocol(AdStateManaging)]) return NO;
    return ((UIViewController<AdStateManaging> *)vc).isLoading;
}

- (BOOL)didLoadSuccessfullyForVC:(UIViewController *)vc {
    if (![vc isKindOfClass:[BaseAdViewController class]]) return NO;
    BaseAdViewController *baseVC = (BaseAdViewController *)vc;
    NSString *text = baseVC.statusLabel.text ?: @"";
    BOOL hasFailure = [text containsString:@"Failed"] ||
                      [text containsString:@"Error"] ||
                      [text containsString:@"No Ad"] ||
                      [text containsString:@"No Fill"];
    BOOL isGreen = [baseVC.statusIndicator.backgroundColor isEqual:[UIColor systemGreenColor]];
    return isGreen && !hasFailure;
}

- (nullable UIView *)adViewForClickTestingOnVC:(UIViewController *)vc {
    if ([vc respondsToSelector:@selector(adViewForClickTesting)]) {
        return [(id<AdStateManaging>)vc adViewForClickTesting];
    }
    return nil;
}

#pragma mark - SDK Init

- (void)triggerInitWithEnvironment:(NSString *)env
                        completion:(void (^)(BOOL success))completion {
    UIViewController *initVC = [self navigateToInit];
    if (!initVC) {
        if (completion) completion(NO);
        return;
    }

    SEL initSel = [self resolveInitSelectorForVC:initVC environment:env];
    if (!initSel) {
        [self logMessage:@"Init VC does not respond to any init selector — aborting"];
        if (completion) completion(NO);
        return;
    }

    __block BOOL completed = NO;
    __block id observer = nil;

    observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:@"cloudXSDKInitialized"
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
        if (completed) return;
        completed = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        if (completion) completion(YES);
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [initVC performSelector:initSel];
#pragma clang diagnostic pop
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSDKInitTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!completed) {
            completed = YES;
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            if (completion) completion(NO);
        }
    });
}

#pragma mark - Logging

- (void)logMessage:(NSString *)message {
    [[DemoAppLogger sharedInstance] logMessage:message];
}

#pragma mark - Tab & VC Resolution (Private)

- (nullable AdDemoTabViewController *)resolveTabViewController {
    UIWindow *window = [self keyWindow];
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

    [self logMessage:@"Could not resolve AdDemoTabViewController for deep link"];
    return nil;
}

- (NSInteger)tabIndexForFormat:(NSString *)format inTabVC:(AdDemoTabViewController *)tabVC {
    NSString *targetClassName = classNameMap()[format];
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
    return -1;
}

- (nullable UIViewController *)vcAtTabIndex:(NSInteger)tabIndex inTabVC:(AdDemoTabViewController *)tabVC {
    if (tabIndex < 0 || tabIndex >= (NSInteger)tabVC.viewControllers.count) return nil;

    UIViewController *vc = tabVC.viewControllers[tabIndex];
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UIViewController *root = ((UINavigationController *)vc).viewControllers.firstObject;
        if (root) return root;
    } else if (vc) {
        return vc;
    }

    // "More" tab fallback
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

- (SEL)initSelectorForEnvironment:(NSString *)env {
    if ([env isEqualToString:@"local"])   return @selector(initializeWithLocalEnvironment);
    if ([env isEqualToString:@"staging"]) return @selector(initializeWithStagingEnvironment);
    if ([env isEqualToString:@"dev"])     return @selector(initializeWithDevEnvironment);
    return @selector(initializeWithProductionEnvironment);
}

- (nullable SEL)resolveInitSelectorForVC:(UIViewController *)vc environment:(NSString *)env {
    SEL envSel = [self initSelectorForEnvironment:env];
    if ([vc respondsToSelector:envSel]) return envSel;
    SEL genericSel = @selector(initializeSDK);
    if ([vc respondsToSelector:genericSel]) return genericSel;
    return nil;
}

- (nullable UIWindow *)keyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) return window;
        }
    }
    return nil;
}

@end

#pragma mark - CLXDeepLinkRouter (Public API)

@implementation CLXDeepLinkRouter

+ (void)setup {
    static CLXDeepLinkRouterAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [[CLXDeepLinkRouterAdapter alloc] init];
        [CLXTestHarnessEngine registerApp:adapter];
    });
}

+ (BOOL)handleURL:(NSURL *)url {
    [self setup];
    return [CLXTestHarnessEngine handleURL:url];
}

+ (void)handleLaunchArguments {
    [self setup];
    [CLXTestHarnessEngine handleLaunchArguments];
}

@end

#else

// CloudXTestHarness not available — provide no-op stubs so the app compiles without the QA pod.
@implementation CLXDeepLinkRouter
+ (void)setup {}
+ (BOOL)handleURL:(NSURL *)url { return NO; }
+ (void)handleLaunchArguments {}
@end

#endif
