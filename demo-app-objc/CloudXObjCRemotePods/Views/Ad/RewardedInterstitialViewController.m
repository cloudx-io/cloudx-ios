#import "RewardedInterstitialViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

@interface RewardedInterstitialViewController ()
@property (nonatomic, strong) id<CLXRewardedInterstitial> rewardedInterstitialAd;
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
    NSLog(@"[RewardedInterstitialViewController] viewWillAppear");
    if ([[CloudXCore shared] isInitialised]) {
        [self loadRewardedInterstitial];
    } else {
        NSLog(@"[RewardedInterstitialViewController] SDK not initialized, rewarded interstitial will be loaded once SDK is initialized.");
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
    // Use actual CloudX placement name from server config (using rewarded placement for rewarded interstitial)
    return @"metaRewarded";
}

- (void)loadRewardedInterstitial {
    NSLog(@"[RewardedInterstitialViewController] loadRewardedInterstitial called");
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[RewardedInterstitialViewController] SDK not initialized");
        return;
    }

    if (self.isLoading || self.rewardedInterstitialAd) {
        NSLog(@"[RewardedInterstitialViewController] Rewarded interstitial ad process already started");
        return;
    }

    NSLog(@"[RewardedInterstitialViewController] Starting rewarded interstitial ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    NSLog(@"[RewardedInterstitialViewController] Using placement: %@", placement);
    
    // Create rewarded interstitial with comprehensive logging
    NSLog(@"[RewardedInterstitialViewController] Calling createRewardedWithPlacement: %@", placement);
    self.rewardedInterstitialAd = [[CloudXCore shared] createRewardedWithPlacement:placement
                                                                          delegate:self];
    
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
    
    if (self.rewardedInterstitialAd.isReady) {
        NSLog(@"✅ Ad is ready. Calling showFromViewController...");
        [self.rewardedInterstitialAd showFromViewController:self];
    } else {
        NSLog(@"⏳ Ad not ready. Will attempt to load.");
        if (!self.isLoading && self.rewardedInterstitialAd) {
            NSLog(@"🔄 Starting new load since not currently loading");
            [self.rewardedInterstitialAd load];
        } else if (self.isLoading) {
            NSLog(@"⏳ Already loading, just waiting for completion");
        } else {
            NSLog(@"❌ No rewarded interstitial instance available, creating new one");
            [self loadRewardedInterstitial];
        }
        [self updateStatusUIWithState:AdStateLoading];
    }
}

#pragma mark - CLXRewardedInterstitialDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ RewardedInterstitial didLoadWithAd - Ad: %@", ad]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ RewardedInterstitial failToLoadWithAd - Error: %@", error.localizedDescription]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Interstitial Error" message:errorMessage];
        self.rewardedInterstitialAd = nil;
        // Don't automatically retry - let user manually retry if needed
        // This prevents the race condition where error shows but ad loads anyway
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 RewardedInterstitial didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ RewardedInterstitial failToShowWithAd - Error: %@", error.localizedDescription]];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedInterstitialAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Interstitial Error" message:errorMessage];
        // Don't automatically retry - let user manually retry if needed
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 RewardedInterstitial didHideWithAd - Ad: %@", ad]];
    self.rewardedInterstitialAd = nil;
    [self loadRewardedInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 RewardedInterstitial didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ RewardedInterstitial impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 RewardedInterstitial revenuePaid - Ad: %@", ad]];
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ RewardedInterstitial closedByUserActionWithAd - Ad: %@", ad]];
    self.rewardedInterstitialAd = nil;
    [self loadRewardedInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)userRewarded:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🎁 RewardedInterstitial userRewarded - Ad: %@", ad]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Reward" message:@"User has earned a reward from interstitial!"];
    });
}

- (void)rewardedVideoStarted:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"▶️ RewardedInterstitial rewardedVideoStarted - Ad: %@", ad]];
}

- (void)rewardedVideoCompleted:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ RewardedInterstitial rewardedVideoCompleted - Ad: %@", ad]];
}

@end
