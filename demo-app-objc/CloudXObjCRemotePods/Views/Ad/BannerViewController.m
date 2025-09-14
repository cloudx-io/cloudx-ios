#import "BannerViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"

@interface BannerViewController ()
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, assign) AdState adState;
@property (nonatomic, strong) UIButton *autoRefreshButton;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@end

@implementation BannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.autoRefreshEnabled = YES; // Default to enabled
    [self setupUI];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)setupUI {
    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // Load Banner button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Banner" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadBannerAd) forControlEvents:UIControlEventTouchUpInside];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:loadButton];
    
    // Show Banner button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show Banner" forState:UIControlStateNormal];
    [showButton addTarget:self action:@selector(showBannerAd) forControlEvents:UIControlEventTouchUpInside];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:showButton];
    
    // Auto-refresh toggle button
    self.autoRefreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.autoRefreshButton setTitle:@"Stop Auto-Refresh" forState:UIControlStateNormal];
    [self.autoRefreshButton addTarget:self action:@selector(toggleAutoRefresh) forControlEvents:UIControlEventTouchUpInside];
    self.autoRefreshButton.backgroundColor = [UIColor systemPurpleColor];
    [self.autoRefreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.autoRefreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.autoRefreshButton.layer.cornerRadius = 8;
    self.autoRefreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:self.autoRefreshButton];
    
    
    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [loadButton.widthAnchor constraintEqualToConstant:200],
        [loadButton.heightAnchor constraintEqualToConstant:44],
        [showButton.widthAnchor constraintEqualToConstant:200],
        [showButton.heightAnchor constraintEqualToConstant:44],
        [self.autoRefreshButton.widthAnchor constraintEqualToConstant:200],
        [self.autoRefreshButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load Banner button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].bannerPlacement;
}

- (void)loadBannerAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Banner is already loading."];
        return;
    }
    
    if (self.bannerAd) {
        [self showAlertWithTitle:@"Info" message:@"Banner already loaded. Use Show Banner to display it."];
        return;
    }
    
    [self loadBanner];
}

- (void)loadBanner {
    if (![[CloudXCore shared] isInitialised]) {
        return;
    }

    if (self.bannerAd) {
        return;
    }

    NSString *placement = [self placementName];
    self.bannerAd = [[CloudXCore shared] createBannerWithPlacement:placement
                                                      viewController:self
                                                          delegate:self
                                                              tmax:nil];
    
    if (!self.bannerAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create banner."];
        return;
    }
    
    // Start loading
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self.bannerAd load];
}

- (void)showBannerAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (!self.bannerAd) {
        [self showAlertWithTitle:@"Error" message:@"No banner loaded. Please load a banner first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Banner is still loading. Please wait."];
        return;
    }
    
    // Check if banner is already in the view hierarchy
    if (self.bannerAd.superview) {
        [self showAlertWithTitle:@"Info" message:@"Banner is already showing."];
        return;
    }
    
    // Add banner to view hierarchy
    [self addBannerToViewHierarchy];
}

- (void)addBannerToViewHierarchy {
    if (!self.bannerAd || self.bannerAd.superview) {
        return;
    }
    
    // Add banner to view hierarchy
    self.bannerAd.translatesAutoresizingMaskIntoConstraints = NO;
    self.bannerAd.backgroundColor = [UIColor redColor]; // DEBUG: Make banner container visible
    
    [self.view addSubview:self.bannerAd];

    [NSLayoutConstraint activateConstraints:@[
        [self.bannerAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.bannerAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.bannerAd.widthAnchor constraintEqualToConstant:320],
        [self.bannerAd.heightAnchor constraintEqualToConstant:50]
    ]];
}

#pragma mark - Auto-Refresh Control

- (void)toggleAutoRefresh {
    if (!self.bannerAd) {
        return;
    }
    
    self.autoRefreshEnabled = !self.autoRefreshEnabled;
    
    if (self.autoRefreshEnabled) {
        [self.bannerAd startAutoRefresh];
        [self.autoRefreshButton setTitle:@"Stop Auto-Refresh" forState:UIControlStateNormal];
        self.autoRefreshButton.backgroundColor = [UIColor systemRedColor];
    } else {
        [self.bannerAd stopAutoRefresh];
        [self.autoRefreshButton setTitle:@"Start Auto-Refresh" forState:UIControlStateNormal];
        self.autoRefreshButton.backgroundColor = [UIColor systemGreenColor];
    }
}

#pragma mark - Property Logging


- (NSString *)adFormatString:(CLXBannerType)adFormat {
    switch (adFormat) {
        case CLXBannerTypeW320H50:
            return @"W320H50 (Standard Banner)";
        case CLXBannerTypeMREC:
            return @"MREC (300x250)";
        default:
            return @"Unknown";
    }
}

- (void)resetAdState {
    if (self.bannerAd) {
        [self.bannerAd removeFromSuperview];
        [self.bannerAd destroy];
    }
    self.bannerAd = nil;
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
}

#pragma mark - CLXBannerDelegate
- (void)didLoadWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Banner didLoadWithAd" ad:ad];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    // Don't auto-show - user must press Show Banner button
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Banner failToLoadWithAd" ad:ad];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 Banner didShowWithAd" ad:ad];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Banner failToShowWithAd" ad:ad];
    
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 Banner didHideWithAd" ad:ad];
    self.bannerAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Banner didClickWithAd" ad:ad];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ Banner impressionOn" ad:ad];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Banner revenuePaid" ad:ad];
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✋ Banner closedByUserActionWithAd" ad:ad];
    self.bannerAd = nil;
}

// NEW MAX SDK Compatibility Delegate Methods
- (void)didExpandAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔍 Banner didExpandAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Banner Expanded!" 
                         message:@"Banner ad expanded to full screen. This is a new MAX SDK compatibility feature."];
    });
}

- (void)didCollapseAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔍 Banner didCollapseAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Banner Collapsed!" 
                         message:@"Banner ad collapsed from full screen. This is a new MAX SDK compatibility feature."];
    });
}

- (void)updateStatusUIWithState:(AdState)state {
    self.adState = state;
    [super updateStatusUIWithState:state];
}


@end 
