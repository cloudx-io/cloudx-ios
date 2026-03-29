#import "RewardedViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "NSError+DemoDescription.h"

@interface RewardedViewController ()
@property (nonatomic, strong) CLXRewarded *rewardedAd;
@property (nonatomic, strong) UserDefaultsSettings *settings;
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
    UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadButton setTitle:@"Load Rewarded" forState:UIControlStateNormal];
    [loadButton addTarget:self action:@selector(loadRewardedAd) forControlEvents:UIControlEventTouchUpInside];
    loadButton.backgroundColor = [UIColor systemGreenColor];
    [loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    loadButton.layer.cornerRadius = 8;
    loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonStack addArrangedSubview:loadButton];
    
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
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [loadButton.widthAnchor constraintEqualToConstant:200],
        [loadButton.heightAnchor constraintEqualToConstant:44],
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
    if (!self.rewardedAd || self.isLoading) {
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
    self.receivedCallbacks = AdCallbackEventNone;
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
        [self.rewardedAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create rewarded ad."];
    }
}

- (void)resetAdState {
    self.rewardedAd = nil;
    self.isLoading = NO;
    self.receivedCallbacks = AdCallbackEventNone;
}

- (void)createRewardedAd {
    if (self.rewardedAd) return;
    NSString *adUnitId = [self adUnitId];
    self.rewardedAd = [[CloudXCore shared] createRewardedWithAdUnitId:adUnitId];
    self.rewardedAd.delegate = self;
    self.rewardedAd.revenueDelegate = self;
}

- (void)showRewardedAd {
    if (self.isLoading) {
        return;
    }
    
    // If ad is ready, show it immediately
    if (self.rewardedAd && self.rewardedAd.isReady) {
        [self.rewardedAd showFromViewController:self
                                      placement:@"demo_rewarded"
                                     customData:@"level:10,bonus:true"];
        return;
    }
    
    // If no ad instance or not ready, create a new one
    if (!self.rewardedAd) {
        [self createRewardedAd];
    }
    
    if (!self.rewardedAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create Rewarded ad."];
        return;
    }
    
    // If we have an ad but it's not ready, start loading
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
        [self showAlertWithTitle:@"Rewarded Ad Show Failed" message:errorMessage];
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

- (void)didPayRevenueForAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventRevenueReceived;
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Rewarded didPayRevenue" ad:ad];
}

- (void)didRewardUserForAd:(CLXAd *)ad withReward:(CLXReward *)reward {
    NSString *logMessage = [NSString stringWithFormat:@"🎁 Rewarded didRewardUser - Reward: %ld %@", (long)reward.amount, reward.label];
    [[DemoAppLogger sharedInstance] logAdEvent:logMessage ad:ad];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *rewardMessage = [NSString stringWithFormat:@"User earned %ld %@!", (long)reward.amount, reward.label];
        [self showAlertWithTitle:@"Reward" message:rewardMessage];
    });
}

@end 
