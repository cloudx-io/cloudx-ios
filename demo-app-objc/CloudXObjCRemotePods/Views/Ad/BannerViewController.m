#import "BannerViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

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
    // Setup main show banner button
    [self setupCenteredButtonWithTitle:@"Show Banner" action:@selector(showBannerAd)];
    
    // Setup auto-refresh toggle button
    self.autoRefreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.autoRefreshButton setTitle:@"Stop Auto-Refresh" forState:UIControlStateNormal];
    [self.autoRefreshButton addTarget:self action:@selector(toggleAutoRefresh) forControlEvents:UIControlEventTouchUpInside];
    self.autoRefreshButton.backgroundColor = [UIColor systemBlueColor];
    [self.autoRefreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.autoRefreshButton.layer.cornerRadius = 8;
    self.autoRefreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.autoRefreshButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.autoRefreshButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [self.autoRefreshButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.autoRefreshButton.widthAnchor constraintEqualToConstant:200],
        [self.autoRefreshButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    // Add placement test button
    UIButton *placementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [placementButton setTitle:@"Test Placement Property" forState:UIControlStateNormal];
    [placementButton addTarget:self action:@selector(testPlacementProperty) forControlEvents:UIControlEventTouchUpInside];
    placementButton.backgroundColor = [UIColor systemOrangeColor];
    [placementButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    placementButton.layer.cornerRadius = 8;
    placementButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:placementButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [placementButton.topAnchor constraintEqualToAnchor:self.autoRefreshButton.bottomAnchor constant:20],
        [placementButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [placementButton.widthAnchor constraintEqualToConstant:200],
        [placementButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[CloudXCore shared] isInitialised] && !self.bannerAd) {
        [self loadBanner];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    // Use actual CloudX placement name from server config
    return @"metaBanner";
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
    }
}

- (void)showBannerAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (self.isLoading) {
        return;
    }
    
    // Check if banner is already in the view hierarchy
    if (self.bannerAd && self.bannerAd.superview) {
        return;
    }
    
    // If we already have a loaded banner, add it to view hierarchy
    if (self.bannerAd && self.bannerAd.isReady) {
        [self addBannerToViewHierarchy];
        return;
    }
    
    // Create and load a new banner ad instance
    if (!self.bannerAd) {
        [self loadBanner];
    }
    
    if (!self.bannerAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create banner."];
        return;
    }
    
    // Start loading - banner will be added to view in didLoadWithAd callback
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self.bannerAd load];
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

- (void)testPlacementProperty {
    if (!self.bannerAd) {
        return;
    }
    
    // Test setting the placement property
    NSString *originalPlacement = self.bannerAd.placement;
    NSString *testPlacement = @"testPlacementValue123";
    
    self.bannerAd.placement = testPlacement;
    
    // Restore original placement
    self.bannerAd.placement = originalPlacement;
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
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Banner didLoadWithAd - Ad: %@", ad]];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    // Add banner to view hierarchy now that it's loaded - this should trigger didShowWithAd and impressionOn
    [self addBannerToViewHierarchy];
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Banner failToLoadWithAd - Error: %@", error.localizedDescription]];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 Banner didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Banner failToShowWithAd - Error: %@", error.localizedDescription]];
    
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 Banner didHideWithAd - Ad: %@", ad]];
    self.bannerAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 Banner didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ Banner impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 Banner revenuePaid - Ad: %@", ad]];
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ Banner closedByUserActionWithAd - Ad: %@", ad]];
    self.bannerAd = nil;
}

// NEW MAX SDK Compatibility Delegate Methods
- (void)didExpandAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔍 Banner didExpandAd - Ad: %@", ad]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Banner Expanded!" 
                         message:@"Banner ad expanded to full screen. This is a new MAX SDK compatibility feature."];
    });
}

- (void)didCollapseAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔍 Banner didCollapseAd - Ad: %@", ad]];
    
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
