#import "InterstitialViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"

@interface InterstitialViewController ()
@property (nonatomic, strong) id<CLXInterstitial> interstitialAd;
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
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].interstitialPlacement;
}

- (void)loadInterstitialAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
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
    if (![[CloudXCore shared] isInitialised]) {
        return;
    }

    if (self.isLoading || self.interstitialAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    // Always preserve the original human-readable placement name for display purposes
    NSString *originalPlacementName = [self placementName];
    
    // Use settings placement ID for SDK call if provided, otherwise use original name
    NSString *placement = originalPlacementName;
    if (_settings.interstitialPlacement.length > 0) {
        placement = _settings.interstitialPlacement;
    }
    
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:placement
                                                                        delegate:self];
    
    // Note: The interstitial ad will internally preserve the original placement name through our CLXAd factory method updates
    
    if (self.interstitialAd) {
        [self.interstitialAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create interstitial."];
    }
}


- (void)showInterstitialAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (!self.interstitialAd) {
        [self showAlertWithTitle:@"Error" message:@"No interstitial loaded. Please load an interstitial first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Interstitial is still loading. Please wait."];
        return;
    }
    
    if (self.interstitialAd.isReady) {
        [self.interstitialAd showFromViewController:self];
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

- (void)didLoadWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Interstitial didLoadWithAd" ad:ad];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Interstitial failToLoadWithAd" ad:ad];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Error" message:errorMessage];
        self.interstitialAd = nil;
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 Interstitial didShowWithAd" ad:ad];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Interstitial failToShowWithAd" ad:ad];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 Interstitial didHideWithAd" ad:ad];
    
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    
    // Don't auto-load - user must press Load Interstitial button
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Interstitial didClickWithAd" ad:ad];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ Interstitial impressionOn" ad:ad];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Interstitial revenuePaid" ad:ad];
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ Interstitial closedByUserActionWithAd - Ad: %@", ad]];
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    // Create new ad instance for next time
    [self loadInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

@end 
