#import "NativeBannerViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "NSError+DemoDescription.h"

@interface NativeBannerViewController ()
@property (nonatomic, strong) CLXNativeAdView *nativeBannerAd;
@property (nonatomic, strong) UIView *adContainerView;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@end

@implementation NativeBannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.settings = [UserDefaultsSettings sharedSettings];
    
    // Create a vertical stack container for button and ad
    UIStackView *mainStack = [[UIStackView alloc] init];
    mainStack.axis = UILayoutConstraintAxisVertical;
    mainStack.spacing = 24;
    mainStack.alignment = UIStackViewAlignmentCenter;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];
    
    // Load Native Banner button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Native Banner" forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loadButton addTarget:self action:@selector(loadNativeBannerAd) forControlEvents:UIControlEventTouchUpInside];
    [mainStack addArrangedSubview:loadButton];
    [loadButton.widthAnchor constraintEqualToConstant:200].active = YES;
    [loadButton.heightAnchor constraintEqualToConstant:44].active = YES;
    
    // Show Native Banner button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show Native Banner" forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [showButton addTarget:self action:@selector(showNativeBannerAd) forControlEvents:UIControlEventTouchUpInside];
    [mainStack addArrangedSubview:showButton];
    [showButton.widthAnchor constraintEqualToConstant:200].active = YES;
    [showButton.heightAnchor constraintEqualToConstant:44].active = YES;
    
    // Create container view for the ad
    self.adContainerView = [[UIView alloc] init];
    self.adContainerView.backgroundColor = [UIColor lightGrayColor];
    self.adContainerView.layer.cornerRadius = 8;
    self.adContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [mainStack addArrangedSubview:self.adContainerView];
    [self.adContainerView.widthAnchor constraintEqualToConstant:self.view.frame.size.width - 40].active = YES;
    [self.adContainerView.heightAnchor constraintEqualToConstant:100].active = YES; // Native banner is smaller
    
    // Center the stack view vertically in the parent view
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [mainStack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load Native Banner button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].nativeBannerPlacement;
}

- (void)loadNativeBannerAd {
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Native banner is already loading."];
        return;
    }
    
    if (self.nativeBannerAd) {
        [self showAlertWithTitle:@"Info" message:@"Native banner already loaded. Use Show Native Banner to display it."];
        return;
    }
    
    [self loadNativeBanner];
}

- (void)loadNativeBanner {
    NSLog(@"[NativeBannerViewController] LOG: loadNativeBanner called");

    if (self.isLoading || self.nativeBannerAd) {
        NSLog(@"[NativeBannerViewController] LOG: Ad process already started, returning.");
        return;
    }

    NSLog(@"[NativeBannerViewController] LOG: Starting native banner ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    if (_settings.nativeMediumPlacement.length > 0) {
        placement = _settings.nativeMediumPlacement;
    }
    NSLog(@"[NativeBannerViewController] LOG: Using placement: '%@'", placement);
    
    self.nativeBannerAd = [[CloudXCore shared] createNativeAdWithPlacement:placement
                                                            viewController:self
                                                                  delegate:self];
    
    if (self.nativeBannerAd) {
        NSLog(@"[NativeBannerViewController] LOG: ✅ Native banner ad instance created successfully: %@", self.nativeBannerAd);
        NSLog(@"[NativeBannerViewController] LOG: Loading native banner ad instance...");
        [self.nativeBannerAd load];
    } else {
        NSLog(@"[NativeBannerViewController] LOG: ❌ Failed to create native banner with placement: '%@'", placement);
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create native banner ad."];
    }
}

- (void)showNativeBannerAd {
    NSLog(@"[NativeBannerViewController] LOG: showNativeBannerAd called.");
    
    if (!self.nativeBannerAd) {
        NSLog(@"[NativeBannerViewController] LOG: No native banner ad instance, loading now...");
        [self loadNativeBanner];
        return;
    }
    
    if (!self.nativeBannerAd.isReady) {
        NSLog(@"[NativeBannerViewController] LOG: Ad not ready, loading now...");
        [self updateStatusUIWithState:AdStateLoading];
        [self.nativeBannerAd load];
        return;
    }
    
    NSLog(@"[NativeBannerViewController] LOG: ✅ Ad is ready. Rendering now.");
    
    // Remove any existing ad view
    for (UIView *subview in self.adContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    // Add the native banner ad view to the container
    self.nativeBannerAd.frame = self.adContainerView.bounds;
    [self.adContainerView addSubview:self.nativeBannerAd];
}

- (void)resetAdState {
    if (self.nativeBannerAd) {
        // CRITICAL: Properly destroy the native banner ad to stop background processing
        [self.nativeBannerAd destroy];
        [self.nativeBannerAd removeFromSuperview];
        self.nativeBannerAd = nil;
    }
}

#pragma mark - CLXNativeDelegate

- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ NativeBanner didLoadAd" ad:ad];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatusUIWithState:AdStateReady];
    });
}

- (void)didFailToLoadAd:(NSString *)placementName error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ NativeBanner failed to load (%@) - Error: %@", placementName, error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeBannerAd = nil;
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Banner Load Failed" message:errorMessage];
    });
}

- (void)didDisplayAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 NativeBanner didDisplayAd" ad:ad];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ NativeBanner failToShowWithAd - Error: %@", error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeBannerAd = nil;
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Banner Show Failed" message:errorMessage];
    });
}

- (void)didHideAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 NativeBanner didHideWithAd - Ad: %@", ad]];
    self.nativeBannerAd = nil;
}

- (void)didClickAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 NativeBanner didClickWithAd - Ad: %@", ad]];
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ NativeBanner didRecordImpressionForAd" ad:ad];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 NativeBanner didPayRevenueForAd" ad:ad];
}

@end
