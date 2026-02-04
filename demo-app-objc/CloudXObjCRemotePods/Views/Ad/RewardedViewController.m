#import "RewardedViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "NSError+DemoDescription.h"

@interface RewardedViewController ()
@property (nonatomic, strong) CLXRewarded *rewardedAd;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@property (nonatomic, strong) UIButton *rewardedLoadButton;
@end

@implementation RewardedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.settings = [UserDefaultsSettings sharedSettings];
    
    // Create a vertical stack for buttons
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // Load Rewarded button
    self.rewardedLoadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.rewardedLoadButton setTitle:@"Load Rewarded" forState:UIControlStateNormal];
    [self.rewardedLoadButton addTarget:self action:@selector(loadRewardedAd) forControlEvents:UIControlEventTouchUpInside];
    self.rewardedLoadButton.backgroundColor = [UIColor systemGreenColor];
    [self.rewardedLoadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.rewardedLoadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.rewardedLoadButton.layer.cornerRadius = 8;
    self.rewardedLoadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:self.rewardedLoadButton];
    
    // Show Rewarded button
    UIButton *showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showButton setTitle:@"Show Rewarded" forState:UIControlStateNormal];
    [showButton addTarget:self action:@selector(showRewardedAd) forControlEvents:UIControlEventTouchUpInside];
    showButton.backgroundColor = [UIColor systemBlueColor];
    [showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    showButton.layer.cornerRadius = 8;
    showButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:showButton];
    
    // Button constraints
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:220],
        [self.rewardedLoadButton.widthAnchor constraintEqualToConstant:200],
        [self.rewardedLoadButton.heightAnchor constraintEqualToConstant:44],
        [showButton.widthAnchor constraintEqualToConstant:200],
        [showButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // No auto-loading - user must press Load Rewarded button
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)placementName {
    return [[CLXDemoConfigManager sharedManager] currentConfig].rewardedPlacement;
}

- (void)loadRewardedAd {
    
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Rewarded ad is already loading."];
        return;
    }
    
    if (self.rewardedAd) {
        [self showAlertWithTitle:@"Info" message:@"Rewarded ad already loaded. Use Show Rewarded to display it."];
        return;
    }
    
    [self loadRewarded];
}

- (void)loadRewarded {
    NSLog(@"[RewardedViewController] loadRewarded called");

    if (self.isLoading || self.rewardedAd) {
        NSLog(@"[RewardedViewController] Rewarded ad process already started");
        return;
    }

    NSLog(@"[RewardedViewController] Starting rewarded ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    if (_settings.rewardedPlacement.length > 0) {
        placement = _settings.rewardedPlacement;
    }
    NSLog(@"[RewardedViewController] Using placement: %@", placement);
    
    // Create rewarded with comprehensive logging
    NSLog(@"[RewardedViewController] Calling createRewardedWithAdUnitId: %@", placement);
    self.rewardedAd = [[CloudXCore shared] createRewardedWithAdUnitId:placement];
    self.rewardedAd.delegate = self;
    
    if (self.rewardedAd) {
        NSLog(@"[RewardedViewController] ✅ Rewarded ad instance created successfully: %@", self.rewardedAd);
        NSLog(@"[RewardedViewController] Loading rewarded ad instance...");
        [self.rewardedAd load];
    } else {
        NSLog(@"[RewardedViewController] ❌ Failed to create rewarded with placement: %@", placement);
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create rewarded ad."];
    }
}

- (void)resetAdState {
    self.rewardedAd = nil;
    self.isLoading = NO;
}

- (void)createRewardedAd {
    if (self.rewardedAd) return;
    NSString *placement = [self placementName];
    NSLog(@"[RewardedViewController] Creating new Rewarded ad instance with placement: %@", placement);
    // SDK config debugging removed to avoid undeclared selector warnings
    self.rewardedAd = [[CloudXCore shared] createRewardedWithAdUnitId:placement];
    self.rewardedAd.delegate = self;
    if (self.rewardedAd) {
        NSLog(@"✅ Rewarded ad instance created successfully: %@", self.rewardedAd);
        [self startPollingReadyState];
    } else {
        NSLog(@"❌ Failed to create rewarded ad instance for placement: %@", placement);
    }
}

- (void)startPollingReadyState {
    // Poll every 0.5 seconds to check if the ad is ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.rewardedAd) {
            NSLog(@"❌ No rewarded ad instance available for polling");
            return;
        }
        
        NSLog(@"🔍 Checking ad ready state...");
        if (self.rewardedAd.isReady) {
            NSLog(@"✅ Ad is now ready from queue");
            self.isLoading = NO;
            [self updateStatusUIWithState:AdStateReady];
            // Do NOT show the ad here!
            return;
        } else {
            NSLog(@"⏳ Ad not ready yet, continuing to poll...");
            self.isLoading = YES;
            [self updateStatusUIWithState:AdStateLoading];
            [self startPollingReadyState];
        }
    });
}

- (void)showRewardedAd {
    NSLog(@"🔄 [RewardedViewController] showRewardedAd called");
    NSLog(@"📊 [RewardedViewController] Current state:");
    NSLog(@"📊 [RewardedViewController] - isLoading: %d", self.isLoading);
    NSLog(@"📊 [RewardedViewController] - rewardedAd: %@", self.rewardedAd);
    NSLog(@"📊 [RewardedViewController] - rewardedAd.isReady: %d", self.rewardedAd.isReady);
    
    if (self.isLoading) {
        NSLog(@"⏳ [RewardedViewController] Already loading an ad, please wait...");
        return;
    }
    
    // If ad is ready, show it immediately
    if (self.rewardedAd && self.rewardedAd.isReady) {
        NSLog(@"👀 [RewardedViewController] Ad ready, showing immediately...");
        NSLog(@"📊 [RewardedViewController] Calling showFromViewController on: %@", self.rewardedAd);
        [self.rewardedAd showFromViewController:self];
        return;
    }
    
    // If no ad instance or not ready, create a new one
    if (!self.rewardedAd) {
        NSLog(@"📱 [RewardedViewController] No ad instance found, creating new one...");
        [self createRewardedAd];
    }
    
    if (!self.rewardedAd) {
        NSLog(@"❌ [RewardedViewController] Failed to create Rewarded ad instance");
        [self showAlertWithTitle:@"Error" message:@"Failed to create Rewarded ad."];
        return;
    }
    
    // If we have an ad but it's not ready, start loading
    if (!self.rewardedAd.isReady) {
        NSLog(@"📱 [RewardedViewController] Ad not ready, starting load...");
        self.isLoading = YES;
        [self.rewardedAd load];
    }
}

#pragma mark - CLXRewardedDelegate

- (void)didLoadAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Rewarded didLoadAd" ad:ad];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    
    // Do NOT show the ad here!
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Rewarded failed to load (%@) - Error: %@", adUnitId, error.localizedDescription]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Ad Load Failed" message:errorMessage];
        
        self.rewardedAd = nil;
    });
}

- (void)didDisplayAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👀 Rewarded didDisplayAd" ad:ad];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logAdEvent:@"❌ Rewarded didFailToDisplayAd" ad:ad];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = nil;
        NSString *errorMessage = error ? [error detailedDemoDescription] : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Ad Display Failed" message:errorMessage];
    });
}

- (void)didHideAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🔚 Rewarded didHideAd" ad:ad];
    self.rewardedAd = nil;
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Rewarded didClickAd" ad:ad];
}

- (void)didRecordImpressionForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👁️ Rewarded didRecordImpressionForAd" ad:ad];
}

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Rewarded didPayRevenueForAd" ad:ad];
}

- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward {
    NSString *logMessage = [NSString stringWithFormat:@"🎁 Rewarded didRewardUser - Amount: %ld %@", (long)reward.amount, reward.label];
    [[DemoAppLogger sharedInstance] logAdEvent:logMessage ad:ad];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"You earned %ld %@!", (long)reward.amount, reward.label];
        [self showAlertWithTitle:@"Reward Earned! 🎉" message:message];
    });
}

#pragma mark - Test Mode Overrides

- (void)resetLoadButton {
    [self.rewardedLoadButton setTitle:@"Load Rewarded" forState:UIControlStateNormal];
}

@end 


