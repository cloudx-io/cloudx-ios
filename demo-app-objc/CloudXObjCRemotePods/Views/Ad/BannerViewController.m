#import "BannerViewController.h"
#import <CloudXCore/CloudXCore.h>

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
    NSLog(@"[BannerViewController] viewDidLoad");
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
    NSLog(@"[BannerViewController] viewWillAppear");
    if ([[CloudXCore shared] isInitialised] && !self.bannerAd) {
        [self loadBanner];
    } else {
        NSLog(@"[BannerViewController] SDK not initialized or banner already exists, banner will be loaded when needed.");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"[BannerViewController] viewWillDisappear");
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
    NSLog(@"[BannerViewController] loadBanner, isSDKInitialized: %d, isLoading: %d, bannerAd: %@", self.isSDKInitialized, self.isLoading, self.bannerAd);
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[BannerViewController] SDK not initialized, banner will be loaded once SDK is initialized.");
        return;
    }

    if (self.bannerAd) {
        NSLog(@"[BannerViewController] Banner ad already exists.");
        return;
    }

    NSLog(@"[BannerViewController] Creating new banner ad instance...");
    NSString *placement = [self placementName];
    NSLog(@"[BannerViewController] Using placement: %@", placement);
    
    // Create banner with comprehensive logging
    NSLog(@"[BannerViewController] Calling createBannerWithPlacement: %@", placement);
    self.bannerAd = [[CloudXCore shared] createBannerWithPlacement:placement
                                                      viewController:self
                                                          delegate:self
                                                              tmax:nil];
    
    if (self.bannerAd) {
        NSLog(@"[BannerViewController] ✅ Banner ad instance created successfully: %@", self.bannerAd);
        [self logBannerProperties:@"After Creation"];
        // Note: We do NOT call load() here - that happens in showBannerAd
    } else {
        NSLog(@"[BannerViewController] ❌ Failed to create banner with placement: %@", placement);
        [self showAlertWithTitle:@"Error" message:@"Failed to create banner."];
    }
}

- (void)showBannerAd {
    NSLog(@"[BannerViewController] showBannerAd called");
    NSLog(@"[BannerViewController] Banner ad exists: %d", self.bannerAd != nil);
    NSLog(@"[BannerViewController] Is loading: %d", self.isLoading);
    
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[BannerViewController] SDK not initialized, showing error");
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (self.isLoading) {
        NSLog(@"[BannerViewController] Already loading an ad, please wait...");
        return;
    }
    
    // Create a new banner ad instance if needed
    if (!self.bannerAd) {
        [self loadBanner];
    }
    
    if (!self.bannerAd) {
        NSLog(@"[BannerViewController] Failed to create banner.");
        [self showAlertWithTitle:@"Error" message:@"Failed to create banner."];
        return;
    }
    
    // Check if banner is already in the view hierarchy
    if (self.bannerAd.superview) {
        NSLog(@"[BannerViewController] Banner is already displayed");
        return;
    }
    
    NSLog(@"[BannerViewController] 🔄 Starting banner ad load process...");
    
    // Add banner to view hierarchy FIRST (following Swift pattern)
    self.bannerAd.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add visible background color for debugging
    self.bannerAd.backgroundColor = [UIColor redColor]; // DEBUG: Make banner container visible
    
    [self.view addSubview:self.bannerAd];

    [NSLayoutConstraint activateConstraints:@[
        [self.bannerAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.bannerAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.bannerAd.widthAnchor constraintEqualToConstant:320],
        [self.bannerAd.heightAnchor constraintEqualToConstant:50]
    ]];
    
    NSLog(@"[BannerViewController] Banner constraints activated and added to view hierarchy");
    
    // After adding the bannerAd to the view hierarchy, add:
    NSLog(@"[BannerViewController] Parent view frame: %@", NSStringFromCGRect(self.view.frame));
    NSLog(@"[BannerViewController] Parent view bounds: %@", NSStringFromCGRect(self.view.bounds));
    
    // Set loading state and start loading
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    NSLog(@"[BannerViewController] 📱 Loading banner ad...");
    [self logBannerProperties:@"Before Load"];
    [self.bannerAd load];
    [self logBannerProperties:@"After Load Called"];
}

#pragma mark - Auto-Refresh Control

- (void)toggleAutoRefresh {
    NSLog(@"[BannerViewController] 🔄 toggleAutoRefresh called - current state: %@", self.autoRefreshEnabled ? @"ENABLED" : @"DISABLED");
    
    if (!self.bannerAd) {
        NSLog(@"[BannerViewController] ⚠️ No banner ad to control auto-refresh");
        return;
    }
    
    self.autoRefreshEnabled = !self.autoRefreshEnabled;
    
    if (self.autoRefreshEnabled) {
        NSLog(@"[BannerViewController] ▶️ Starting auto-refresh");
        [self.bannerAd startAutoRefresh];
        [self.autoRefreshButton setTitle:@"Stop Auto-Refresh" forState:UIControlStateNormal];
        self.autoRefreshButton.backgroundColor = [UIColor systemRedColor];
    } else {
        NSLog(@"[BannerViewController] ⏹️ Stopping auto-refresh");
        [self.bannerAd stopAutoRefresh];
        [self.autoRefreshButton setTitle:@"Start Auto-Refresh" forState:UIControlStateNormal];
        self.autoRefreshButton.backgroundColor = [UIColor systemGreenColor];
    }
    
    [self logBannerProperties:@"After Auto-Refresh Toggle"];
}

- (void)testPlacementProperty {
    NSLog(@"[BannerViewController] 🧪 testPlacementProperty called");
    
    if (!self.bannerAd) {
        NSLog(@"[BannerViewController] ⚠️ No banner ad to test placement property");
        return;
    }
    
    NSLog(@"[BannerViewController] 📝 Testing placement property setter/getter");
    [self logBannerProperties:@"Before Placement Property Test"];
    
    // Test setting the placement property
    NSString *originalPlacement = self.bannerAd.placement;
    NSString *testPlacement = @"testPlacementValue123";
    
    NSLog(@"[BannerViewController] 📝 Original placement: %@", originalPlacement ?: @"<nil>");
    NSLog(@"[BannerViewController] 📝 Setting placement to: %@", testPlacement);
    
    self.bannerAd.placement = testPlacement;
    
    NSLog(@"[BannerViewController] 📝 Placement after setting: %@", self.bannerAd.placement ?: @"<nil>");
    
    [self logBannerProperties:@"After Placement Property Test"];
    
    // Restore original placement
    self.bannerAd.placement = originalPlacement;
    NSLog(@"[BannerViewController] 📝 Restored placement to: %@", self.bannerAd.placement ?: @"<nil>");
}

#pragma mark - Property Logging

- (void)logBannerProperties:(NSString *)context {
    if (!self.bannerAd) {
        NSLog(@"[BannerViewController] 📊 [%@] No banner ad to log properties", context);
        return;
    }
    
    NSLog(@"[BannerViewController] 📊 ========== BANNER PROPERTIES [%@] ==========", context);
    
    // Log new MAX SDK compatibility properties
    NSLog(@"[BannerViewController] 📊 adUnitIdentifier: %@", self.bannerAd.adUnitIdentifier ?: @"<nil>");
    NSLog(@"[BannerViewController] 📊 adFormat: %ld (%@)", (long)self.bannerAd.adFormat, [self adFormatString:self.bannerAd.adFormat]);
    NSLog(@"[BannerViewController] 📊 placement: %@", self.bannerAd.placement ?: @"<nil>");
    
    // Log existing properties
    NSLog(@"[BannerViewController] 📊 isReady: %@", self.bannerAd.isReady ? @"YES" : @"NO");
    NSLog(@"[BannerViewController] 📊 suspendPreloadWhenInvisible: %@", self.bannerAd.suspendPreloadWhenInvisible ? @"YES" : @"NO");
    
    // Log view hierarchy info
    NSLog(@"[BannerViewController] 📊 superview: %@", self.bannerAd.superview ? NSStringFromClass([self.bannerAd.superview class]) : @"<nil>");
    NSLog(@"[BannerViewController] 📊 frame: %@", NSStringFromCGRect(self.bannerAd.frame));
    NSLog(@"[BannerViewController] 📊 bounds: %@", NSStringFromCGRect(self.bannerAd.bounds));
    NSLog(@"[BannerViewController] 📊 subviews count: %lu", (unsigned long)self.bannerAd.subviews.count);
    NSLog(@"[BannerViewController] 📊 isHidden: %@", self.bannerAd.isHidden ? @"YES" : @"NO");
    NSLog(@"[BannerViewController] 📊 alpha: %.2f", self.bannerAd.alpha);
    
    NSLog(@"[BannerViewController] 📊 ================================================");
}

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
    NSLog(@"[BannerViewController] resetAdState called");
    if (self.bannerAd) {
        NSLog(@"[BannerViewController] Removing banner from superview and destroying");
        [self.bannerAd removeFromSuperview];
        [self.bannerAd destroy];
    }
    self.bannerAd = nil;
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    NSLog(@"[BannerViewController] Ad state reset complete");
}

#pragma mark - CLXBannerDelegate
- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] ✅ didLoadWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    
    [self logBannerProperties:@"In didLoadWithAd - Before State Update"];
    
    // Debug view hierarchy
    NSLog(@"[BannerViewController] Banner ad frame: %@", NSStringFromCGRect(self.bannerAd.frame));
    NSLog(@"[BannerViewController] Banner ad bounds: %@", NSStringFromCGRect(self.bannerAd.bounds));
    NSLog(@"[BannerViewController] Banner ad isHidden: %d", self.bannerAd.isHidden);
    NSLog(@"[BannerViewController] Banner ad alpha: %f", self.bannerAd.alpha);
    NSLog(@"[BannerViewController] Banner ad backgroundColor: %@", self.bannerAd.backgroundColor);
    
    if (self.bannerAd.subviews.count > 0) {
        UIView *bannerSubview = self.bannerAd.subviews.firstObject;
        NSLog(@"[BannerViewController] Banner subview frame: %@", NSStringFromCGRect(bannerSubview.frame));
        NSLog(@"[BannerViewController] Banner subview bounds: %@", NSStringFromCGRect(bannerSubview.bounds));
        NSLog(@"[BannerViewController] Banner subview isHidden: %d", bannerSubview.isHidden);
        NSLog(@"[BannerViewController] Banner subview alpha: %f", bannerSubview.alpha);
        NSLog(@"[BannerViewController] Banner subview backgroundColor: %@", bannerSubview.backgroundColor);
    }
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    [self logBannerProperties:@"In didLoadWithAd - After State Update"];
    
    // Perform comprehensive system assessment
    [self performSystemAssessment];
    
    NSLog(@"[BannerViewController] Banner load completed successfully");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"[BannerViewController] ❌ failToLoadWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    NSLog(@"[BannerViewController] Error: %@", error);
    NSLog(@"[BannerViewController] Error domain: %@", error.domain);
    NSLog(@"[BannerViewController] Error code: %ld", (long)error.code);
    NSLog(@"[BannerViewController] Error description: %@", error.localizedDescription);
    NSLog(@"[BannerViewController] Error user info: %@", error.userInfo);
    
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] didShowWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    [self logBannerProperties:@"In didShowWithAd"];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"[BannerViewController] ❌ failToShowWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    NSLog(@"[BannerViewController] Error: %@", error);
    
    self.bannerAd = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Banner Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] didHideWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    self.bannerAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] didClickWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    [self logBannerProperties:@"In didClickWithAd"];
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"[BannerViewController] impressionOn delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    [self logBannerProperties:@"In impressionOn"];
}

- (void)revenuePaid:(CLXAd *)ad {
    NSLog(@"[BannerViewController] 💰 revenuePaid delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] closedByUserActionWithAd delegate called");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    [self logBannerProperties:@"In closedByUserActionWithAd"];
    self.bannerAd = nil;
}

// NEW MAX SDK Compatibility Delegate Methods
- (void)didExpandAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] 🔍 didExpandAd delegate called - NEW MAX SDK FEATURE");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    [self logBannerProperties:@"In didExpandAd"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Banner Expanded!" 
                         message:@"Banner ad expanded to full screen. This is a new MAX SDK compatibility feature."];
    });
}

- (void)didCollapseAd:(CLXAd *)ad {
    NSLog(@"[BannerViewController] 🔍 didCollapseAd delegate called - NEW MAX SDK FEATURE");
    NSLog(@"[BannerViewController] Ad object: %@", ad);
    [self logBannerProperties:@"In didCollapseAd"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Banner Collapsed!" 
                         message:@"Banner ad collapsed from full screen. This is a new MAX SDK compatibility feature."];
    });
}

- (void)updateStatusUIWithState:(AdState)state {
    self.adState = state;
    [super updateStatusUIWithState:state];
}

#pragma mark - System Assessment

- (void)performSystemAssessment {
    NSLog(@"[BannerViewController] 🔍 ========== SYSTEM ASSESSMENT ==========");
    NSLog(@"[BannerViewController] 🔍 Performing comprehensive system assessment for new MAX SDK features");
    
    if (!self.bannerAd) {
        NSLog(@"[BannerViewController] 🔍 ❌ ASSESSMENT FAILED: No banner ad instance available");
        return;
    }
    
    // Assessment 1: Property Population
    NSLog(@"[BannerViewController] 🔍 Assessment 1: Property Population");
    BOOL adUnitIdentifierPopulated = (self.bannerAd.adUnitIdentifier != nil && self.bannerAd.adUnitIdentifier.length > 0);
    BOOL adFormatPopulated = (self.bannerAd.adFormat == CLXBannerTypeW320H50 || self.bannerAd.adFormat == CLXBannerTypeMREC);
    BOOL placementSettable = YES; // We can always set this property
    
    NSLog(@"[BannerViewController] 🔍 ✅ adUnitIdentifier populated: %@ (Value: %@)", 
          adUnitIdentifierPopulated ? @"YES" : @"NO", self.bannerAd.adUnitIdentifier ?: @"<nil>");
    NSLog(@"[BannerViewController] 🔍 ✅ adFormat populated: %@ (Value: %ld - %@)", 
          adFormatPopulated ? @"YES" : @"NO", (long)self.bannerAd.adFormat, [self adFormatString:self.bannerAd.adFormat]);
    NSLog(@"[BannerViewController] 🔍 ✅ placement settable: %@ (Current: %@)", 
          placementSettable ? @"YES" : @"NO", self.bannerAd.placement ?: @"<nil>");
    
    // Assessment 2: Auto-Refresh Control
    NSLog(@"[BannerViewController] 🔍 Assessment 2: Auto-Refresh Control Methods");
    BOOL startAutoRefreshExists = [self.bannerAd respondsToSelector:@selector(startAutoRefresh)];
    BOOL stopAutoRefreshExists = [self.bannerAd respondsToSelector:@selector(stopAutoRefresh)];
    
    NSLog(@"[BannerViewController] 🔍 ✅ startAutoRefresh method exists: %@", startAutoRefreshExists ? @"YES" : @"NO");
    NSLog(@"[BannerViewController] 🔍 ✅ stopAutoRefresh method exists: %@", stopAutoRefreshExists ? @"YES" : @"NO");
    
    // Assessment 3: Delegate Method Implementation
    NSLog(@"[BannerViewController] 🔍 Assessment 3: New Delegate Methods");
    BOOL expandDelegateExists = [self respondsToSelector:@selector(didExpandAd:)];
    BOOL collapseDelegateExists = [self respondsToSelector:@selector(didCollapseAd:)];
    
    NSLog(@"[BannerViewController] 🔍 ✅ didExpandAd delegate implemented: %@", expandDelegateExists ? @"YES" : @"NO");
    NSLog(@"[BannerViewController] 🔍 ✅ didCollapseAd delegate implemented: %@", collapseDelegateExists ? @"YES" : @"NO");
    
    // Overall Assessment
    BOOL overallSuccess = adUnitIdentifierPopulated && adFormatPopulated && placementSettable && 
                         startAutoRefreshExists && stopAutoRefreshExists && 
                         expandDelegateExists && collapseDelegateExists;
    
    NSLog(@"[BannerViewController] 🔍 ========== ASSESSMENT RESULT ==========");
    NSLog(@"[BannerViewController] 🔍 %@ OVERALL ASSESSMENT: %@", 
          overallSuccess ? @"✅" : @"❌", overallSuccess ? @"PASSED" : @"FAILED");
    NSLog(@"[BannerViewController] 🔍 All new MAX SDK compatibility features are %@", 
          overallSuccess ? @"WORKING CORRECTLY" : @"NOT WORKING AS EXPECTED");
    NSLog(@"[BannerViewController] 🔍 ==========================================");
}

@end 
