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
    if ([[CloudXCore shared] isInitialised]) {
        [self loadInterstitial];
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
    if (![[CloudXCore shared] isInitialised]) {
        return;
    }

    if (self.isLoading || self.interstitialAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    self.interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:placement
                                                                        delegate:self];
    
    if (self.interstitialAd) {
        [self.interstitialAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create interstitial."];
    }
}


- (void)showInterstitialAd {
    if (self.interstitialAd.isReady) {
        [self.interstitialAd showFromViewController:self];
    } else {
        self.showAdWhenLoaded = YES;
        if (!self.isLoading && self.interstitialAd) {
            [self.interstitialAd load];
        } else if (!self.isLoading) {
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
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Interstitial didLoadWithAd - Ad: %@", ad]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateReady];

    if (self.showAdWhenLoaded) {
        self.showAdWhenLoaded = NO; // Reset flag
        [self.interstitialAd showFromViewController:self];
    }
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Interstitial failToLoadWithAd - Error: %@", error.localizedDescription]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Error" message:errorMessage];
        self.interstitialAd = nil;
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 Interstitial didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Interstitial failToShowWithAd - Error: %@", error.localizedDescription]];
    [self updateStatusUIWithState:AdStateNoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"Interstitial Ad Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 Interstitial didHideWithAd - Ad: %@", ad]];
    
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    
    // Create new ad instance for next time
    [self loadInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 Interstitial didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ Interstitial impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 Interstitial revenuePaid - Ad: %@", ad]];
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for interstitial ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ Interstitial closedByUserActionWithAd - Ad: %@", ad]];
    self.showAdWhenLoaded = NO;
    self.interstitialAd = nil;
    // Create new ad instance for next time
    [self loadInterstitial];
    [self updateStatusUIWithState:AdStateNoAd];
}

@end 
