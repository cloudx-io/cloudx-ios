#import "InterstitialViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

@interface InterstitialViewController ()
@property (nonatomic, strong) id<CLXInterstitial> interstitialAd;
@property (nonatomic, assign) BOOL showAdWhenLoaded;
@end

@implementation InterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCenteredButtonWithTitle:@"Show Interstitial" action:@selector(showInterstitialAd)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"[InterstitialViewController] viewWillAppear");
    if ([[CloudXCore shared] isInitialised]) {
        [self loadInterstitial];
    } else {
        NSLog(@"[InterstitialViewController] SDK not initialized, interstitial will be loaded once SDK is initialized.");
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
    return @"metaInterstitial";
}

- (void)loadInterstitial {
    NSLog(@"[InterstitialViewController] loadInterstitial called");
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[InterstitialViewController] SDK not initialized");
        return;
    }

    if (self.isLoading || self.interstitialAd) {
        NSLog(@"[InterstitialViewController] Interstitial ad process already started");
        return;
    }

    NSLog(@"[InterstitialViewController] Starting interstitial ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    NSLog(@"[InterstitialViewController] Using placement: %@", placement);
    
    // Log SDK configuration details
    NSLog(@"[InterstitialViewController] SDK initialization status: %d", [[CloudXCore shared] isInitialised]);
    
    // Create interstitial with comprehensive logging
    NSLog(@"[InterstitialViewController] Calling createInterstitialWithPlacement: %@", placement);
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:placement
                                                                        delegate:self];
    
    if (self.interstitialAd) {
        NSLog(@"[InterstitialViewController] ✅ Interstitial ad instance created successfully: %@", self.interstitialAd);
        NSLog(@"[InterstitialViewController] Loading interstitial ad instance...");
        [self.interstitialAd load];
    } else {
        NSLog(@"[InterstitialViewController] ❌ Failed to create interstitial with placement: %@", placement);
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create interstitial."];
    }
}

- (void)startPollingReadyState {
    // Poll every 0.5 seconds to check if the ad is ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.interstitialAd) return;
        
        if (self.interstitialAd.isReady) {
            NSLog(@"✅ Ad is now ready from queue");
            [self updateStatusUIWithState:AdStateReady];
        } else {
            NSLog(@"⏳ Ad not ready yet, continuing to poll...");
            [self updateStatusUIWithState:AdStateLoading];
            [self startPollingReadyState];
        }
    });
}

- (void)showInterstitialAd {
    NSLog(@"[InterstitialViewController] 'Show Interstitial' button tapped.");
    
    if (self.interstitialAd.isReady) {
        NSLog(@"✅ Ad is ready. Calling showFromViewController...");
        [self.interstitialAd showFromViewController:self];
    } else {
        NSLog(@"⏳ Ad not ready. Will attempt to load and show automatically.");
        self.showAdWhenLoaded = YES;
        if (!self.isLoading && self.interstitialAd) {
            NSLog(@"🔄 Starting new load since not currently loading");
            [self.interstitialAd load];
        } else if (self.isLoading) {
            NSLog(@"⏳ Already loading, just waiting for completion");
        } else {
            NSLog(@"❌ No interstitial instance available, creating new one");
            [self loadInterstitial];
        }
        [self updateStatusUIWithState:AdStateLoading];
    }
}

- (void)resetAdState {
    self.interstitialAd = nil;
    self.isLoading = NO;
    self.showAdWhenLoaded = NO;
    [self updateStatusUIWithState:AdStateNoAd];
}

#pragma mark - CLXInterstitialDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ Interstitial ad loaded successfully");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Interstitial didLoadWithAd - Ad: %@", ad]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];

    if (self.showAdWhenLoaded) {
        NSLog(@"✅ showAdWhenLoaded is true. Showing ad now.");
        self.showAdWhenLoaded = NO; // Reset flag
        [self.interstitialAd showFromViewController:self];
    }
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Failed to load Interstitial Ad: %@", error);
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Interstitial failToLoadWithAd - Error: %@", error.localizedDescription]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Error" message:errorMessage];
        
        self.interstitialAd = nil;
        // Don't automatically retry - let user manually retry if needed
        // This prevents the race condition where error shows but ad loads anyway
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 Interstitial ad did show");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 Interstitial didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Interstitial ad fail to show: %@", error);
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Interstitial failToShowWithAd - Error: %@", error.localizedDescription]];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Error" message:errorMessage];
        // Don't automatically retry - let user manually retry if needed
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 Interstitial ad did hide");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 Interstitial didHideWithAd - Ad: %@", ad]];
    NSLog(@"📊 [InterstitialViewController] Current state before auto-load:");
    NSLog(@"📊 [InterstitialViewController] - isLoading: %d", self.isLoading);
    NSLog(@"📊 [InterstitialViewController] - showAdWhenLoaded: %d", self.showAdWhenLoaded);
    NSLog(@"📊 [InterstitialViewController] - interstitialAd: %@", self.interstitialAd);
    
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    
    NSLog(@"📊 [InterstitialViewController] Starting auto-load after dismissal...");
    // Create new ad instance for next time
    [self loadInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 Interstitial ad did click");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 Interstitial didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ Interstitial ad impression recorded");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ Interstitial impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    NSLog(@"💰 Interstitial ad revenue paid callback triggered");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 Interstitial revenuePaid - Ad: %@", ad]];
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for interstitial ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ Interstitial ad closed by user action");
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ Interstitial closedByUserActionWithAd - Ad: %@", ad]];
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    // Create new ad instance for next time
    [self loadInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

@end 
