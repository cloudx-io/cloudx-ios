#import "BannerViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "NSError+DemoDescription.h"

@interface BannerViewController ()
@property (nonatomic, strong) CLXBannerAdView *bannerAd;
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, assign) AdState adState;
@property (nonatomic, strong) UIButton *autoRefreshButton;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong) UserDefaultsSettings *settings;
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

- (NSString *)adUnitId {
    return [[CLXDemoConfigManager sharedManager] currentConfig].bannerAdUnitId;
}

- (void)loadBannerAd {
    self.receivedCallbacks = AdCallbackEventNone;
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
    
    // Get ad unit ID from config, with settings override if provided
    NSString *adUnitId = [self adUnitId];
    if (_settings.bannerAdUnitId.length > 0) {
        adUnitId = _settings.bannerAdUnitId;
    }
    
    self.bannerAd = [[CloudXCore shared] createBannerWithAdUnitId:adUnitId];
    self.bannerAd.delegate = self;
    self.bannerAd.revenueDelegate = self;
    self.bannerAd.placement = @"demo_banner";
    self.bannerAd.customData = @"screen:home,position:bottom";
    
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
    self.receivedCallbacks = AdCallbackEventNone;
    [self updateStatusUIWithState:AdStateNoAd];
}

#pragma mark - CLXBannerDelegate
- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Banner didLoadAd" ad:ad];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    // Don't auto-show - user must press Show Banner button
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Banner failed to load (%@) - Error: %@", adUnitId, error ? error.localizedDescription : @"Unknown error"]];
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Load Failed" message:errorMessage];
    });
}

- (void)didClickAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventClicked;
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Banner didClickAd" ad:ad];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventRevenueReceived;
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Banner didPayRevenue" ad:ad];
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

- (nullable UIView *)adViewForClickTesting {
    return self.bannerAd;
}

@end 
