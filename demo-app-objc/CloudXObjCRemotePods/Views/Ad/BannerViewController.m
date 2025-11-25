#import "BannerViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "GPPScenarioPickerView.h"
#import "NSError+DemoDescription.h"

@interface BannerViewController ()
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, assign) AdState adState;
@property (nonatomic, strong) UIButton *autoRefreshButton;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@property (nonatomic, strong) GPPScenarioPickerView *gppScenarioPicker;
@end

@implementation BannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.autoRefreshEnabled = YES;
    [self setupUI];
    self.settings = [UserDefaultsSettings sharedSettings];
    [self updateStatusUIWithState:AdStateNoAd];
}

// Override to position status label above banner area
- (void)setupStatusUI {
    // Setup status indicator stack
    self.statusStack = [[UIStackView alloc] init];
    self.statusStack.axis = UILayoutConstraintAxisHorizontal;
    self.statusStack.spacing = 8;
    self.statusStack.alignment = UIStackViewAlignmentCenter;
    self.statusStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.statusIndicator = [[UIView alloc] init];
    self.statusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusIndicator.layer.cornerRadius = 6;
    self.statusIndicator.clipsToBounds = YES;
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.statusStack addArrangedSubview:self.statusIndicator];
    [self.statusStack addArrangedSubview:self.statusLabel];
    
    [self.view addSubview:self.statusStack];
    
    // Position status label above banner area (banner is 50px high + 30px spacing)
    [NSLayoutConstraint activateConstraints:@[
        [self.statusStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.statusStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-80],
        [self.statusIndicator.widthAnchor constraintEqualToConstant:12],
        [self.statusIndicator.heightAnchor constraintEqualToConstant:12]
    ]];
}

- (void)setupUI {
    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 12;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // GPP Scenario Picker - Encapsulated Test Component
    //
    // PURPOSE: Provides a self-contained UI for selecting and applying GPP privacy test scenarios.
    // This component handles ALL GPP test logic internally, keeping BannerViewController clean.
    //
    // USAGE:
    // 1. Simply instantiate and add to view hierarchy (no configuration needed)
    // 2. Component self-manages: button creation, alert presentation, privacy SDK calls
    // 3. Zero code footprint in parent - follows DRY principle
    //
    // FEATURES:
    // - 9 privacy test scenarios (COPPA, CCPA, GPP, ATT, regional variations)
    // - Action sheet picker with full scenario names and descriptions
    // - Automatic CloudXCore privacy SDK integration
    // - Console logging for test verification
    //
    // TESTING COVERAGE:
    // - CCPA Consent/Opt-Out
    // - COPPA (age-restricted users)
    // - ATT (iOS App Tracking Transparency) - Must be manually enabled/disabled in iOS Settings
    // - GPP regional (US-CA, US-National, EU)
    // - Combined scenarios (COPPA + GPP consent precedence)
    //
    self.gppScenarioPicker = [[GPPScenarioPickerView alloc] init];
    self.gppScenarioPicker.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:self.gppScenarioPicker];
    
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
    
    
    // Button constraints - positioned below Show Logs button with proper spacing
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [loadButton.widthAnchor constraintEqualToConstant:200],
        [loadButton.heightAnchor constraintEqualToConstant:44],
        [self.autoRefreshButton.widthAnchor constraintEqualToConstant:200],
        [self.autoRefreshButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    // Auto-create and add banner to view hierarchy immediately
    [self createAndAddBannerToView];
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
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Banner is already loading."];
        return;
    }
    
    if (!self.bannerAd) {
        [self createAndAddBannerToView];
    }
    
    if (!self.bannerAd) {
        return; // Failed to create
    }
    
    // Start loading
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self.bannerAd load];
}

- (void)createAndAddBannerToView {
    if (self.bannerAd) return;
    
    // Always preserve the original human-readable placement name for display purposes
    NSString *originalPlacementName = [self placementName];
    
    // Use settings placement ID for SDK call if provided, otherwise use original name
    NSString *placement = originalPlacementName;
    if (_settings.bannerPlacement.length > 0) {
        placement = _settings.bannerPlacement;
    }
    
    self.bannerAd = [[CloudXCore shared] createBannerWithPlacement:placement
                                                      viewController:self
                                                          delegate:self];
    
    if (!self.bannerAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create banner."];
        return;
    }
    
    // Add banner to view hierarchy immediately
    [self addBannerToViewHierarchy];
}

- (void)loadBanner {
    // Legacy method - now just calls the new method
    [self createAndAddBannerToView];
}

// showBannerAd method removed - Banner is auto-added to view on push

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
- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Banner didLoadAd" ad:ad];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    // Don't auto-show - user must press Show Banner button
}

- (void)didFailToLoadAdWithError:(CLXError *)error {
    // No ad object exists on failure, so use logMessage instead of logAdEvent
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Banner failed to load - Error: %@", error ? error.localizedDescription : @"Unknown error"]];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Load Failed" message:errorMessage];
    });
}

- (void)didDisplayAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 Banner didDisplayAd" ad:ad];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Banner didFailToDisplayAd" ad:ad];
    
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Show Failed" message:errorMessage];
    });
}

- (void)didHideAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 Banner didHideAd" ad:ad];
    self.bannerAd = nil;
}

- (void)didClickAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Banner didClickAd" ad:ad];
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ Banner didRecordImpressionForAd" ad:ad];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Banner didPayRevenueForAd" ad:ad];
}

// Banner-specific delegate methods
- (void)didExpandAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔍 Banner didExpandAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Banner Expanded!" 
                         message:@"Banner ad expanded to full screen. This is a new MAX SDK compatibility feature."];
    });
}

- (void)didCollapseAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔽 Banner didCollapseAd" ad:ad];
    
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
