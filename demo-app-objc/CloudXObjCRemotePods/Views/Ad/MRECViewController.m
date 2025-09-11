#import "MRECViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

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
    if ([[CloudXCore shared] isInitialised]) {
        [self createMRECAd];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)createMRECAd {
    if (self.mrecAd) return;
    NSString *placement = [self placementName];
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement viewController:self delegate:self];
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
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ MREC didLoadWithAd - Ad: %@", ad]];
    self.isLoading = NO;
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ MREC failToLoadWithAd - Error: %@", error.localizedDescription]];
    self.isLoading = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"MREC Error" message:errorMessage];
    });
}

- (void)didShowWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👀 MREC didShowWithAd - Ad: %@", ad]];
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ MREC failToShowWithAd - Error: %@", error.localizedDescription]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        [self showAlertWithTitle:@"MREC Error" message:errorMessage];
    });
}

- (void)didHideWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔚 MREC didHideWithAd - Ad: %@", ad]];
    self.mrecAd = nil;
}

- (void)didClickWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👆 MREC didClickWithAd - Ad: %@", ad]];
}

- (void)impressionOn:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"👁️ MREC impressionOn - Ad: %@", ad]];
}

- (void)revenuePaid:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"💰 MREC revenuePaid - Ad: %@", ad]];
    
    // Show revenue alert to demonstrate the callback
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"Revenue Paid!" 
                         message:@"NURL was successfully sent to server. Revenue callback triggered for MREC ad."];
    });
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✋ MREC closedByUserActionWithAd - Ad: %@", ad]];
    self.mrecAd = nil;
}

// Banner-specific delegate methods (MREC is a banner type)
- (void)didExpandAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔍 MREC didExpandAd - Ad: %@", ad]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"MREC Expanded!" 
                         message:@"MREC ad expanded to full screen."];
    });
}

- (void)didCollapseAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🔍 MREC didCollapseAd - Ad: %@", ad]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertWithTitle:@"MREC Collapsed!" 
                         message:@"MREC ad collapsed from full screen."];
    });
}

- (NSString *)placementName {
    // Use actual CloudX placement name from server config
    return @"metaMREC";
}

- (void)loadMREC {
    if (![[CloudXCore shared] isInitialised]) {
        return;
    }

    if (self.isLoading || self.mrecAd) {
        return;
    }

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];

    NSString *placement = [self placementName];
    self.mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement
                                                 viewController:self
                                                      delegate:self];
    
    if (self.mrecAd) {
        [self.mrecAd load];
    } else {
        self.isLoading = NO;
        [self updateStatusUIWithState:AdStateNoAd];
        [self showAlertWithTitle:@"Error" message:@"Failed to create MREC."];
    }
}

@end 