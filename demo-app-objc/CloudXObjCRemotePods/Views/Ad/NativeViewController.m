#import "NativeViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

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
    
    // Create the button
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
    if ([[CloudXCore shared] isInitialised]) {
        [self loadNative];
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
    return @"metaNative";
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
        [self showAlertWithTitle:@"SDK Not Ready" message:@"Please wait for SDK initialization to complete."];
        return;
    }
    
    if (!self.nativeAd) {
        [self loadNative];
        return;
    }
    
    if (!self.nativeAd.isReady) {
        [self updateStatusUIWithState:AdStateLoading];
        [self.nativeAd load];
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
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Native didLoadWithAd - Ad: %@", ad]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatusUIWithState:AdStateReady];
    });
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Native failToLoadWithAd - Error: %@", error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Ad Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 Native didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Native failToShowWithAd - Error: %@", error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Native Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 Native didHideWithAd - Ad: %@", ad]];
    self.nativeAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 Native didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ Native impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 Native revenuePaid - Ad: %@", ad]];
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for native ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ Native closedByUserActionWithAd - Ad: %@", ad]];
    self.nativeAd = nil;
}

@end 