#import "NativeBannerViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

@interface NativeBannerViewController ()
@property (nonatomic, strong) CLXNativeAdView *nativeBannerAd;
@property (nonatomic, strong) UIView *adContainerView;
@end

@implementation NativeBannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a vertical stack container for button and ad
    UIStackView *mainStack = [[UIStackView alloc] init];
    mainStack.axis = UILayoutConstraintAxisVertical;
    mainStack.spacing = 24;
    mainStack.alignment = UIStackViewAlignmentCenter;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];
    
    // Create the button
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
    NSLog(@"[NativeBannerViewController] viewWillAppear");
    if ([[CloudXCore shared] isInitialised]) {
        [self loadNativeBanner];
    } else {
        NSLog(@"[NativeBannerViewController] SDK not initialized, native banner will be loaded once SDK is initialized.");
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
    // Use actual CloudX placement name from server config (using native placement for native banner)
    return @"metaNative";
}

- (void)loadNativeBanner {
    NSLog(@"[NativeBannerViewController] LOG: loadNativeBanner called");
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[NativeBannerViewController] LOG: SDK not initialized, returning.");
        return;
    }

    if (self.isLoading || self.nativeBannerAd) {
        NSLog(@"[NativeBannerViewController] LOG: Ad process already started, returning.");
        return;
    }

    NSLog(@"[NativeBannerViewController] LOG: Starting native banner ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
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
    
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[NativeBannerViewController] LOG: SDK not initialized, showing error");
        [self showAlertWithTitle:@"SDK Not Ready" message:@"Please wait for SDK initialization to complete."];
        return;
    }
    
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
    [self.nativeBannerAd removeFromSuperview];
    self.nativeBannerAd = nil;
}

#pragma mark - CLXNativeDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ NativeBanner didLoadWithAd - Ad: %@", ad]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatusUIWithState:AdStateReady];
    });
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ NativeBanner failToLoadWithAd - Error: %@", error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeBannerAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Banner Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 NativeBanner didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ NativeBanner failToShowWithAd - Error: %@", error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeBannerAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Banner Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 NativeBanner didHideWithAd - Ad: %@", ad]];
    self.nativeBannerAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 NativeBanner didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ NativeBanner impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 NativeBanner revenuePaid - Ad: %@", ad]];
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for native banner ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ NativeBanner closedByUserActionWithAd - Ad: %@", ad]];
    self.nativeBannerAd = nil;
}

@end
