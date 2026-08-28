#import "AppOpenViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "NSError+DemoDescription.h"

@interface AppOpenViewController ()
@property (nonatomic, strong) CLXAppOpen *appOpenAd;
@property (nonatomic, assign) BOOL showAdWhenLoaded;
@end

@implementation AppOpenViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];

    // Load App Open button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load App Open" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadAppOpenAd) forControlEvents:UIControlEventTouchUpInside];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:loadButton];

    // Show App Open button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show App Open" forState:UIControlStateNormal];
    [showButton addTarget:self action:@selector(showAppOpenAd) forControlEvents:UIControlEventTouchUpInside];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:showButton];

    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:220],
        [loadButton.widthAnchor constraintEqualToConstant:200],
        [loadButton.heightAnchor constraintEqualToConstant:44],
        [showButton.widthAnchor constraintEqualToConstant:200],
        [showButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load App Open button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Skip cleanup when a fullscreen ad is presented on top — the ad object must
    // stay alive to receive show/click/close delegate callbacks. On a tab switch
    // presentedViewController is nil, so cleanup proceeds normally.
    if (!self.presentedViewController) {
        [self resetAdState];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)adUnitId {
    return [[CLXDemoConfigManager sharedManager] currentConfig].appOpenAdUnitId;
}

- (void)loadAppOpenAd {
    self.receivedCallbacks = AdCallbackEventNone;
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"App Open is already loading."];
        return;
    }

    if (self.appOpenAd) {
        [self showAlertWithTitle:@"Info" message:@"App Open already loaded. Use Show App Open to display it."];
        return;
    }

    [self loadAppOpen];
}

- (void)loadAppOpen {

    if (self.isLoading || self.appOpenAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *adUnitId = [self adUnitId];

    self.appOpenAd = [[CloudXCore shared] createAppOpenWithAdUnitId:adUnitId];
    self.appOpenAd.delegate = self;
    self.appOpenAd.revenueDelegate = self;

    if (self.appOpenAd) {
        [self.appOpenAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create app open."];
    }
}


- (void)showAppOpenAd {

    if (!self.appOpenAd) {
        [self showAlertWithTitle:@"Error" message:@"No app open loaded. Please load an app open first."];
        return;
    }

    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"App Open is still loading. Please wait."];
        return;
    }

    if (self.appOpenAd.isReady) {
        [self.appOpenAd showFromViewController:self
                                    placement:@"demo_app_open"
                                   customData:@"level:5,coins:100"];
    } else {
        [self showAlertWithTitle:@"Error" message:@"App Open is not ready. Please try loading again."];
    }
}

- (void)resetAdState {
    // CRITICAL: Call destroy before releasing to clean up WebViews and prevent zombie WebProcess
    if (self.appOpenAd) {
        [self.appOpenAd destroy];
    }
    self.appOpenAd = nil;
    self.isLoading = NO;
    self.showAdWhenLoaded = NO;
    self.receivedCallbacks = AdCallbackEventNone;
    [self updateStatusUIWithState:AdStateNoAd];
}

#pragma mark - CLXAppOpenDelegate

- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ AppOpen didLoadAd" ad:ad];
    self.isLoading = NO;
    self.receivedCallbacks |= AdCallbackEventLoaded;
    [self updateStatusUIWithState:AdStateReady];
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    // No ad object exists on failure, so use logMessage instead of logAdEvent
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ AppOpen failed to load (%@) - Error: %@", adUnitId, error ? error.localizedDescription : @"Unknown error"]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"App Open Ad Load Failed" message:errorMessage];
        // CRITICAL: Call destroy to clean up any partial state (including WebViews)
        if (self.appOpenAd) {
            [self.appOpenAd destroy];
        }
        self.appOpenAd = nil;
    });
}

- (void)didDisplayAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventDisplayed;
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 AppOpen didDisplayAd" ad:ad];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ AppOpen didFailToDisplayAd" ad:ad];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];

    dispatch_async(dispatch_get_main_queue(), ^{
        // CRITICAL: Call destroy before releasing to clean up WebViews
        if (self.appOpenAd) {
            [self.appOpenAd destroy];
        }
        self.appOpenAd = nil;
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"App Open Ad Show Failed" message:errorMessage];
    });
}

- (void)didHideAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventHidden;
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 AppOpen didHideAd" ad:ad];

    self.showAdWhenLoaded = NO;

    // CRITICAL: Call destroy to ensure full cleanup even after successful close
    if (self.appOpenAd) {
        [self.appOpenAd destroy];
    }
    self.appOpenAd = nil;

    // Don't auto-load - user must press Load App Open button
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventClicked;
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 AppOpen didClickAd" ad:ad];
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ AppOpen didRecordImpressionForAd" ad:ad];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventRevenueReceived;
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 AppOpen didPayRevenueForAd" ad:ad];
}

@end
