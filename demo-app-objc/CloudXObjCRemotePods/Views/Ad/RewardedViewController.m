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
    // Skip cleanup when a fullscreen ad is presented on top — the ad object must
    // stay alive to receive show/click/close delegate callbacks. On a tab switch
    // presentedViewController is nil, so cleanup proceeds normally.
    if (!self.presentedViewController) {
        [self resetAdState];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)adUnitId {
    return [[CLXDemoConfigManager sharedManager] currentConfig].rewardedAdUnitId;
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
    if (self.isLoading || self.rewardedAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *adUnitId = [self adUnitId];
    if (_settings.rewardedAdUnitId.length > 0) {
        adUnitId = _settings.rewardedAdUnitId;
    }

    self.rewardedAd = [[CloudXCore shared] createRewardedWithAdUnitId:adUnitId];
    self.rewardedAd.delegate = self;
    self.rewardedAd.revenueDelegate = self;
    
    if (self.rewardedAd) {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Loading rewarded ad (adUnit: %@)", adUnitId]];
        [self.rewardedAd load];
    } else {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to create rewarded ad (adUnit: %@)", adUnitId]];
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
    NSString *adUnitId = [self adUnitId];
    self.rewardedAd = [[CloudXCore shared] createRewardedWithAdUnitId:adUnitId];
    self.rewardedAd.delegate = self;
    self.rewardedAd.revenueDelegate = self;
    if (self.rewardedAd) {
        [self startPollingReadyState];
    } else {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to create rewarded ad (adUnit: %@)", adUnitId]];
    }
}

- (void)startPollingReadyState {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.rewardedAd) {
            return;
        }
        
        if (self.rewardedAd.isReady) {
            self.isLoading = NO;
            [self updateStatusUIWithState:AdStateReady];
            return;
        } else {
            self.isLoading = YES;
            [self updateStatusUIWithState:AdStateLoading];
            [self startPollingReadyState];
        }
    });
}

- (void)showRewardedAd {
    if (self.isLoading) {
        return;
    }
    
    if (self.rewardedAd && self.rewardedAd.isReady) {
        [self.rewardedAd showFromViewController:self placement:@"rewarded_demo" customData:nil];
        return;
    }
    
    if (!self.rewardedAd) {
        [self createRewardedAd];
    }
    
    if (!self.rewardedAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create Rewarded ad."];
        return;
    }
    
    if (!self.rewardedAd.isReady) {
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


