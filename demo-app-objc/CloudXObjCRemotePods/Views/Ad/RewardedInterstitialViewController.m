#import "RewardedInterstitialViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "NSError+DemoDescription.h"

@interface RewardedInterstitialViewController ()
@property (nonatomic, strong) CLXRewarded *rewardedInterstitialAd;
@end

@implementation RewardedInterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // Load Rewarded Interstitial button
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Rewarded Interstitial" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadRewardedInterstitialAd) forControlEvents:UIControlEventTouchUpInside];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:loadButton];
    
    // Show Rewarded Interstitial button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show Rewarded Interstitial" forState:UIControlStateNormal];
    [showButton addTarget:self action:@selector(showRewardedInterstitialAd) forControlEvents:UIControlEventTouchUpInside];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:showButton];
    
    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [loadButton.widthAnchor constraintEqualToConstant:250],
        [loadButton.heightAnchor constraintEqualToConstant:44],
        [showButton.widthAnchor constraintEqualToConstant:250],
        [showButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load Rewarded Interstitial button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].rewardedInterstitialPlacement;
}

- (void)loadRewardedInterstitialAd {
    NSLog(@"[RewardedInterstitialViewController] loadRewardedInterstitialAd called");

    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Rewarded Interstitial is already loading."];
        return;
    }
    
    if (self.rewardedInterstitialAd) {
        [self showAlertWithTitle:@"Info" message:@"Rewarded Interstitial already loaded. Use Show button to display it."];
        return;
    }

    NSLog(@"[RewardedInterstitialViewController] Starting rewarded interstitial ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    NSLog(@"[RewardedInterstitialViewController] Using placement: %@", placement);
    
    // Create rewarded interstitial with comprehensive logging
    NSLog(@"[RewardedInterstitialViewController] Calling createRewardedWithAdUnitId: %@", placement);
    self.rewardedInterstitialAd = [[CloudXCore shared] createRewardedWithAdUnitId:placement];
    self.rewardedInterstitialAd.delegate = self;
    self.rewardedInterstitialAd.revenueDelegate = self;

    if (self.rewardedInterstitialAd) {
        NSLog(@"[RewardedInterstitialViewController] ✅ Rewarded interstitial ad instance created successfully: %@", self.rewardedInterstitialAd);
        NSLog(@"[RewardedInterstitialViewController] Loading rewarded interstitial ad instance...");
        [self.rewardedInterstitialAd load];
    } else {
        NSLog(@"[RewardedInterstitialViewController] ❌ Failed to create rewarded interstitial with placement: %@", placement);
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create rewarded interstitial ad."];
    }
}

- (void)resetAdState {
    self.rewardedInterstitialAd = nil;
    self.isLoading = NO;
}

- (void)showRewardedInterstitialAd {
    NSLog(@"[RewardedInterstitialViewController] 'Show Rewarded Interstitial' button tapped.");
    
    if (!self.rewardedInterstitialAd) {
        [self showAlertWithTitle:@"Error" message:@"No rewarded interstitial loaded. Please load first."];
        return;
    }
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Rewarded Interstitial is still loading. Please wait."];
        return;
    }
    
    if (self.rewardedInterstitialAd.isReady) {
        [self.rewardedInterstitialAd showFromViewController:self];
    } else {
        [self showAlertWithTitle:@"Error" message:@"Rewarded Interstitial is not ready. Please try loading again."];
    }
}

#pragma mark - CLXRewardedInterstitialDelegate

- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ RewardedInterstitial didLoadWithAd - Ad: %@", ad]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ RewardedInterstitial failed to load (%@) - Error: %@", adUnitId, error.localizedDescription]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Interstitial Load Failed" message:errorMessage];
        self.rewardedInterstitialAd = nil;
        // Don't automatically retry - let user manually retry if needed
    });
}

- (void)didDisplayAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 RewardedInterstitial didShowWithAd - Ad: %@", ad]];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ RewardedInterstitial failToShowWithAd - Error: %@", error.localizedDescription]];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedInterstitialAd = nil;
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Interstitial Show Failed" message:errorMessage];
        // Don't automatically retry - let user manually retry if needed
    });
}

- (void)didHideAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 RewardedInterstitial didHideWithAd - Ad: %@", ad]];
    self.rewardedInterstitialAd = nil;
    // Don't auto-load - user must press Load Rewarded Interstitial button
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 RewardedInterstitial didClickWithAd - Ad: %@", ad]];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 RewardedInterstitial revenuePaid - Ad: %@", ad]];
}

- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward {
    NSString *logMessage = [NSString stringWithFormat:@"🎁 RewardedInterstitial didRewardUser - Amount: %ld %@", (long)reward.amount, reward.label];
    [[DemoAppLogger sharedInstance] logAdEvent:logMessage ad:ad];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Reward" message:[NSString stringWithFormat:@"User earned %ld %@!", (long)reward.amount, reward.label]];
    });
}

@end
