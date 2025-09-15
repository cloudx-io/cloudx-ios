#import "NativeViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"

@interface NativeViewController ()
@property (nonatomic, strong) CLXNativeAdView *nativeAd;
@property (nonatomic, strong) UIView *adContainerView;
@end

@implementation NativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a vertical stack container for button and ad
    UIStackView *mainStack = [[UIStackView alloc] init];
    mainStack.axis = UILayoutConstraintAxisVertical;
    mainStack.spacing = 24;
    mainStack.alignment = UIStackViewAlignmentCenter;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];
    
    // Load Native button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Native" forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loadButton addTarget:self action:@selector(loadNativeAd) forControlEvents:UIControlEventTouchUpInside];
    [mainStack addArrangedSubview:loadButton];
    [loadButton.widthAnchor constraintEqualToConstant:200].active = YES;
    [loadButton.heightAnchor constraintEqualToConstant:44].active = YES;
    
    // Show Native button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show Native" forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [showButton addTarget:self action:@selector(showNativeAd) forControlEvents:UIControlEventTouchUpInside];
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
    [self.adContainerView.heightAnchor constraintEqualToConstant:250].active = YES;
    
    // Center the stack view vertically in the parent view
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [mainStack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load Native button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].nativePlacement;
}

- (void)loadNativeAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Native ad is already loading."];
        return;
    }
    
    if (self.nativeAd) {
        [self showAlertWithTitle:@"Info" message:@"Native ad already loaded. Use Show Native to display it."];
        return;
    }
    
    [self loadNative];
}

- (void)loadNative {
    if (![[CloudXCore shared] isInitialised]) {
        return;
    }

    if (self.isLoading || self.nativeAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    self.nativeAd = [[CloudXCore shared] createNativeAdWithPlacement:placement
                                                      viewController:self
                                                            delegate:self];
    
    if (self.nativeAd) {
        [self.nativeAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create native ad."];
    }
}

- (void)showNativeAd {
    if (![[CloudXCore shared] isInitialised]) {
        [self showAlertWithTitle:@"Error" message:@"SDK not initialized. Please initialize SDK first."];
        return;
    }
    
    if (!self.nativeAd) {
        [self showAlertWithTitle:@"Error" message:@"No native ad loaded. Please load a native ad first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Native ad is still loading. Please wait."];
        return;
    }
    
    if (!self.nativeAd.isReady) {
        [self showAlertWithTitle:@"Error" message:@"Native ad is not ready. Please try loading again."];
        return;
    }
    
    // Remove any existing ad view
    for (UIView *subview in self.adContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    // Add the native ad view to the container
    self.nativeAd.frame = self.adContainerView.bounds;
    [self.adContainerView addSubview:self.nativeAd];
}

- (void)resetAdState {
    [self.nativeAd removeFromSuperview];
    self.nativeAd = nil;
}

#pragma mark - CLXNativeDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Native didLoadWithAd" ad:ad];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateReady];
    });
    
    // Don't auto-show - user must press Show Native button
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Native failToLoadWithAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Ad Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 Native didShowWithAd" ad:ad];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Native failToShowWithAd" ad:ad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 Native didHideWithAd" ad:ad];
    self.nativeAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Native didClickWithAd" ad:ad];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ Native impressionOn" ad:ad];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Native revenuePaid" ad:ad];
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✋ Native closedByUserActionWithAd" ad:ad];
    self.nativeAd = nil;
}

@end 