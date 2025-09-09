#import "RewardedInterstitialViewController.h"
#import <CloudXCore/CloudXCore.h>

@interface RewardedInterstitialViewController ()
@property (nonatomic, strong) id<CLXRewardedInterstitial> rewardedInterstitialAd;
@end

@implementation RewardedInterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCenteredButtonWithTitle:@"Show Rewarded Interstitial" action:@selector(showRewardedInterstitialAd)];
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
    NSLog(@"✅ Rewarded interstitial ad loaded successfully");
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Failed to load Rewarded Interstitial Ad: %@", error);
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
    NSLog(@"👀 Rewarded interstitial ad did show");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Rewarded interstitial ad fail to show: %@", error);
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedInterstitialAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Interstitial Error" message:errorMessage];
        // Don't automatically retry - let user manually retry if needed
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Rewarded interstitial ad did hide");
    self.rewardedInterstitialAd = nil;
    [self loadRewardedInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Rewarded interstitial ad did click");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Rewarded interstitial ad impression recorded");
}

- (void)revenuePaid:(CLXAd *)ad {
    NSLog(@"💰 Rewarded interstitial ad revenue paid callback triggered");
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for rewarded interstitial ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Rewarded interstitial ad closed by user action");
    self.rewardedInterstitialAd = nil;
    [self loadRewardedInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)userRewarded:(CLXAd *)ad {
    NSLog(@"🎁 User rewarded!");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Reward" message:@"User has earned a reward from interstitial!"];
    });
}

- (void)rewardedVideoStarted:(CLXAd *)ad {
    NSLog(@"▶️ Rewarded interstitial started");
}

- (void)rewardedVideoCompleted:(CLXAd *)ad {
    NSLog(@"✅ Rewarded interstitial completed");
}

@end
