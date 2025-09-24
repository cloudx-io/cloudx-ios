#import "MRECViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"

@interface MRECViewController ()
@property (nonatomic, strong) CLXBannerAdView *mrecAd;
@property (nonatomic, strong) UIButton *autoRefreshButton;
@property (nonatomic, assign) BOOL autoRefreshEnabled;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@end

@implementation MRECViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.autoRefreshEnabled = YES; // Default to enabled
    self.settings = [UserDefaultsSettings sharedSettings];
    
    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // Load MREC button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load MREC" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadMRECAd) forControlEvents:UIControlEventTouchUpInside];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:loadButton];
    
    // Show button removed - MREC is auto-added to view on push
    
    // Auto-refresh toggle button (positioned separately above status label)
    self.autoRefreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.autoRefreshButton setTitle:@"Stop Auto-Refresh" forState:UIControlStateNormal];
    [self.autoRefreshButton addTarget:self action:@selector(toggleAutoRefresh) forControlEvents:UIControlEventTouchUpInside];
    self.autoRefreshButton.backgroundColor = [UIColor systemPurpleColor];
    [self.autoRefreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.autoRefreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.autoRefreshButton.layer.cornerRadius = 8;
    self.autoRefreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.autoRefreshButton];
    
    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [loadButton.widthAnchor constraintEqualToConstant:200],
        [loadButton.heightAnchor constraintEqualToConstant:44],
        
        // Auto-refresh button positioned above status label
        [self.autoRefreshButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.autoRefreshButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-80],
        [self.autoRefreshButton.widthAnchor constraintEqualToConstant:200],
        [self.autoRefreshButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    // Auto-create and add MREC to view hierarchy immediately
    [self createAndAddMRECToView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update status based on current ad state
    if (self.mrecAd && !self.isLoading) {
        [self updateStatusUIWithState:AdStateReady];
    } else if (self.isLoading) {
        [self updateStatusUIWithState:AdStateLoading];
    } else {
        [self updateStatusUIWithState:AdStateNoAd];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    // Ensure cleanup even if viewWillDisappear wasn't called
    [self resetAdState];
}

- (void)loadMRECAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"MREC is already loading."];
        return;
    }
    
    if (!self.mrecAd) {
        [self createAndAddMRECToView];
    }
    
    if (!self.mrecAd) {
        return; // Failed to create
    }
    
    // Start loading
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self.mrecAd load];
}

- (void)createAndAddMRECToView {
    if (self.mrecAd) return;
    
    NSString *placement = [self placementName];
    if (_settings.mrecPlacement.length > 0) {
        placement = _settings.mrecPlacement;
    }
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement viewController:self delegate:self];
    
    if (!self.mrecAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create MREC."];
        return;
    }
    
    // Add MREC to view hierarchy immediately
    self.mrecAd.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mrecAd];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mrecAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.mrecAd.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:210],
        [self.mrecAd.widthAnchor constraintEqualToConstant:300],
        [self.mrecAd.heightAnchor constraintEqualToConstant:250]
    ]];
}

- (void)createMRECAd {
    // Legacy method - now just calls the new method
    [self createAndAddMRECToView];
}

// showMRECAd method removed - MREC is auto-added to view on push

- (void)resetAdState {
    if (self.mrecAd) {
        // CRITICAL: Properly destroy the MREC to stop auto-refresh timers and background processing
        [self.mrecAd destroy];
        [self.mrecAd removeFromSuperview];
        self.mrecAd = nil;
    }
    self.isLoading = NO;
}

- (void)toggleAutoRefresh {
    if (!self.mrecAd) {
        return;
    }
    
    self.autoRefreshEnabled = !self.autoRefreshEnabled;
    
    if (self.autoRefreshEnabled) {
        [self.mrecAd startAutoRefresh];
        [self.autoRefreshButton setTitle:@"Stop Auto-Refresh" forState:UIControlStateNormal];
        self.autoRefreshButton.backgroundColor = [UIColor systemRedColor];
    } else {
        [self.mrecAd stopAutoRefresh];
        [self.autoRefreshButton setTitle:@"Start Auto-Refresh" forState:UIControlStateNormal];
        self.autoRefreshButton.backgroundColor = [UIColor systemGreenColor];
    }
}

#pragma mark - CLXBannerDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ MREC didLoadWithAd" ad:ad];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    // Don't auto-show - user must press Show MREC button
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ MREC failToLoadWithAd" ad:ad];
    self.isLoading = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"MREC Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 MREC didShowWithAd" ad:ad];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ MREC failToShowWithAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"MREC Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 MREC didHideWithAd" ad:ad];
    self.mrecAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 MREC didClickWithAd" ad:ad];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ MREC impressionOn" ad:ad];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 MREC revenuePaid" ad:ad];
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✋ MREC closedByUserActionWithAd" ad:ad];
    self.mrecAd = nil;
}

// Banner-specific delegate methods (MREC is a banner type)
- (void)didExpandAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔍 MREC didExpandAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"MREC Expanded!" 
                         message:@"MREC ad expanded to full screen."];
    });
}

- (void)didCollapseAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔍 MREC didCollapseAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"MREC Collapsed!" 
                         message:@"MREC ad collapsed from full screen."];
    });
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].mrecPlacement;
}

- (void)loadMREC {
    if (![[CloudXCore shared] isInitialised]) {
        return;
    }

    if (self.isLoading || self.mrecAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement
                                                 viewController:self
                                                      delegate:self];
    
    if (self.mrecAd) {
        [self.mrecAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create MREC."];
    }
}

@end 
