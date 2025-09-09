#import "RewardedViewController.h"
#import <CloudXCore/CloudXCore.h>

@interface RewardedViewController ()
@property (nonatomic, strong) id<CLXRewardedInterstitial> rewardedAd;
@end

@implementation RewardedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCenteredButtonWithTitle:@"Show Rewarded" action:@selector(showRewardedAd)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"[RewardedViewController] viewWillAppear");
    if ([[CloudXCore shared] isInitialised]) {
        [self loadRewarded];
    } else {
        NSLog(@"[RewardedViewController] SDK not initialized, rewarded ad will be loaded once SDK is initialized.");
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
    return @"metaRewarded";
}

- (void)loadRewarded {
    NSLog(@"[RewardedViewController] loadRewarded called");
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[RewardedViewController] SDK not initialized");
        return;
    }

    if (self.isLoading || self.rewardedAd) {
        NSLog(@"[RewardedViewController] Rewarded ad process already started");
        return;
    }

    NSLog(@"[RewardedViewController] Starting rewarded ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    NSLog(@"[RewardedViewController] Using placement: %@", placement);
    
    // Log SDK configuration details
    NSLog(@"[RewardedViewController] SDK initialization status: %d", [[CloudXCore shared] isInitialised]);
    
    // Create rewarded with comprehensive logging
    NSLog(@"[RewardedViewController] Calling createRewardedWithPlacement: %@", placement);
    self.rewardedAd = [[CloudXCore shared] createRewardedWithPlacement:placement
                                                              delegate:self];
    
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
    self.rewardedAd = [[CloudXCore shared] createRewardedWithPlacement:placement delegate:self];
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

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ Rewarded ad loaded successfully");
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];
    // Do NOT show the ad here!
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Failed to load Rewarded Ad: %@", error);
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Ad Error" message:errorMessage];
        
        self.rewardedAd = nil;
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 Rewarded ad did show");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Rewarded ad fail to show: %@", error);
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Rewarded Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Rewarded ad did hide");
    self.rewardedAd = nil;
    // Create new ad instance for next time
    [self createRewardedAd];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Rewarded ad did click");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Rewarded ad impression recorded");
}

- (void)revenuePaid:(CLXAd *)ad {
    NSLog(@"💰 Rewarded ad revenue paid callback triggered");
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for rewarded ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Rewarded ad closed by user action");
    self.rewardedAd = nil;
    // Create new ad instance for next time
    [self createRewardedAd];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)userRewarded:(CLXAd *)ad {
    NSLog(@"🎁 User rewarded!");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Reward" message:@"User has earned a reward!"];
    });
}

- (void)rewardedVideoStarted:(CLXAd *)ad {
    NSLog(@"▶️ Rewarded video started");
}

- (void)rewardedVideoCompleted:(CLXAd *)ad {
    NSLog(@"✅ Rewarded video completed");
}

@end 
