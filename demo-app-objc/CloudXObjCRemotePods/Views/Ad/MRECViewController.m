#import "MRECViewController.h"
#import <CloudXCore/CloudXCore.h>

@interface MRECViewController ()
@property (nonatomic, strong) CLXBannerAdView *mrecAd;
@end

@implementation MRECViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCenteredButtonWithTitle:@"Show MREC" action:@selector(showMRECAd)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"[MRECViewController] viewWillAppear");
    if ([[CloudXCore shared] isInitialised]) {
        [self createMRECAd];
    } else {
        NSLog(@"[MRECViewController] SDK not initialized, MREC will be loaded once SDK is initialized.");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)createMRECAd {
    if (self.mrecAd) return;
    NSString *placement = [self placementName];
    NSLog(@"[MRECViewController] Creating new MREC ad instance with placement: %@", placement);
    // SDK config debugging removed to avoid undeclared selector warnings
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement viewController:self delegate:self];
    if (self.mrecAd) {
        NSLog(@"✅ MREC ad instance created successfully: %@", self.mrecAd);
    } else {
        NSLog(@"❌ Failed to create MREC ad instance for placement: %@", placement);
    }
}

- (void)showMRECAd {
    if (!self.mrecAd) {
        [self showAlertWithTitle:@"Error" message:@"Failed to create MREC."];
        return;
    }
    
    self.mrecAd.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mrecAd];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mrecAd.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.mrecAd.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.mrecAd.widthAnchor constraintEqualToConstant:300],
        [self.mrecAd.heightAnchor constraintEqualToConstant:250]
    ]];
    
    self.isLoading = YES;
    [self.mrecAd load];
}

- (void)resetAdState {
    [self.mrecAd removeFromSuperview];
    self.mrecAd = nil;
    self.isLoading = NO;
}

#pragma mark - CLXBannerDelegate

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"✅ MREC loaded successfully");
    self.isLoading = NO;
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ Failed to load MREC Ad: %@", error);
    self.isLoading = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"MREC Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSLog(@"👀 MREC did show");
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"❌ MREC fail to show: %@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"MREC Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSLog(@"🔚 MREC did hide");
    self.mrecAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSLog(@"👆 MREC did click");
}

- (void)impressionOn:(CLXAd *)ad {
    NSLog(@"👁️ MREC impression recorded");
}

- (void)revenuePaid:(CLXAd *)ad {
    NSLog(@"💰 MREC revenue paid callback triggered");
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for MREC ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSLog(@"✋ MREC closed by user action");
    self.mrecAd = nil;
}

- (NSString *)placementName {
    // Use actual CloudX placement name from server config
    return @"metaMREC";
}

- (void)loadMREC {
    NSLog(@"[MRECViewController] loadMREC called");
    if (![[CloudXCore shared] isInitialised]) {
        NSLog(@"[MRECViewController] SDK not initialized");
        return;
    }

    if (self.isLoading || self.mrecAd) {
        NSLog(@"[MRECViewController] MREC ad process already started");
        return;
    }

    NSLog(@"[MRECViewController] Starting MREC ad load process...");
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    NSLog(@"[MRECViewController] Using placement: %@", placement);
    
    // Log SDK configuration details
    NSLog(@"[MRECViewController] SDK initialization status: %d", [[CloudXCore shared] isInitialised]);
    
    // Create MREC with comprehensive logging
    NSLog(@"[MRECViewController] Calling createMRECWithPlacement: %@", placement);
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement
                                                 viewController:self
                                                      delegate:self];
    
    if (self.mrecAd) {
        NSLog(@"[MRECViewController] ✅ MREC ad instance created successfully: %@", self.mrecAd);
        NSLog(@"[MRECViewController] Loading MREC ad instance...");
        [self.mrecAd load];
    } else {
        NSLog(@"[MRECViewController] ❌ Failed to create MREC with placement: %@", placement);
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create MREC."];
    }
}

@end 