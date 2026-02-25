#import "InterstitialViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "NSError+DemoDescription.h"

@interface InterstitialViewController ()
@property (nonatomic, strong) CLXInterstitial *interstitialAd;
@property (nonatomic, assign) BOOL showAdWhenLoaded;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@end

@implementation InterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.settings = [UserDefaultsSettings sharedSettings];
    
    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // Load Interstitial button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Interstitial" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadInterstitialAd) forControlEvents:UIControlEventTouchUpInside];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:loadButton];
    
    // Show Interstitial button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show Interstitial" forState:UIControlStateNormal];
    [showButton addTarget:self action:@selector(showInterstitialAd) forControlEvents:UIControlEventTouchUpInside];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:showButton];
    
    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [loadButton.widthAnchor constraintEqualToConstant:200],
        [loadButton.heightAnchor constraintEqualToConstant:44],
        [showButton.widthAnchor constraintEqualToConstant:200],
        [showButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load Interstitial button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Only reset if we're actually leaving the tab — not when a fullscreen ad
    // is presented over us (which also triggers viewWillDisappear).
    if (!self.interstitialAd || self.isLoading) {
        [self resetAdState];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)adUnitId {
    return [[CLXDemoConfigManager sharedManager] currentConfig].interstitialAdUnitId;
}

- (void)loadInterstitialAd {
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Interstitial is already loading."];
        return;
    }
    
    if (self.interstitialAd) {
        [self showAlertWithTitle:@"Info" message:@"Interstitial already loaded. Use Show Interstitial to display it."];
        return;
    }
    
    [self loadInterstitial];
}

- (void)loadInterstitial {

    if (self.isLoading || self.interstitialAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    // Get ad unit ID from config, with settings override if provided
    NSString *adUnitId = [self adUnitId];
    if (_settings.interstitialAdUnitId.length > 0) {
        adUnitId = _settings.interstitialAdUnitId;
    }
    
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithAdUnitId:adUnitId];
    self.interstitialAd.delegate = self;
    self.interstitialAd.revenueDelegate = self;
    
    if (self.interstitialAd) {
        [self.interstitialAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create interstitial."];
    }
}


- (void)showInterstitialAd {
    
    if (!self.interstitialAd) {
        [self showAlertWithTitle:@"Error" message:@"No interstitial loaded. Please load an interstitial first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Interstitial is still loading. Please wait."];
        return;
    }
    
    if (self.interstitialAd.isReady) {
        [self.interstitialAd showFromViewController:self
                                          placement:@"demo_interstitial"
                                         customData:@"level:5,coins:100"];
    } else {
        [self showAlertWithTitle:@"Error" message:@"Interstitial is not ready. Please try loading again."];
    }
}

- (void)resetAdState {
    self.interstitialAd = nil;
    self.isLoading = NO;
    self.showAdWhenLoaded = NO;
    [self updateStatusUIWithState:AdStateNoAd];
}

#pragma mark - CLXInterstitialDelegate

- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Interstitial didLoadAd" ad:ad];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Interstitial failed to load (%@) - Error: %@", adUnitId, error ? error.localizedDescription : @"Unknown error"]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Load Failed" message:errorMessage];
        self.interstitialAd = nil;
    });
}

- (void)didDisplayAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 Interstitial didDisplayAd" ad:ad];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Interstitial didFailToDisplayAd" ad:ad];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Show Failed" message:errorMessage];
    });
}

- (void)didHideAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 Interstitial didHideAd" ad:ad];
    
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    
    // Don't auto-load - user must press Load Interstitial button
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Interstitial didClickAd" ad:ad];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Interstitial didPayRevenue" ad:ad];
}

@end 
