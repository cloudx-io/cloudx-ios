#import "FirstLookViewController.h"
#import "AdMobDemoConfig.h"
#import "AdMobFirstLookSource.h"
#import "CLXDemoConfigManager.h"
#import "CloudXFirstLookSource.h"
#import "DemoAppLogger.h"
#import "DemoFlowLayout.h"
#import "DemoSdkStartup.h"
#import "FirstLookInterstitialController.h"
#import "LiveLogTextView.h"
#import "RetryScheduler.h"

@interface FirstLookViewController ()
@property (nonatomic, strong) UILabel *initializationStatusLabel;
@property (nonatomic, strong) UILabel *interstitialStatusLabel;
@property (nonatomic, strong) LiveLogTextView *logTextView;
@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, strong) RetryScheduler *retry;
@property (nonatomic, strong, nullable) DemoSdkStartup *startup;
@property (nonatomic, strong, nullable) FirstLookInterstitialController *controller;
@end

@implementation FirstLookViewController

- (void)dealloc {
    [_controller dispose];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"First Look";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.initializationStatusLabel = [DemoFlowLayout makeStatusLabel];
    self.interstitialStatusLabel = [DemoFlowLayout makeStatusLabel];
    self.interstitialStatusLabel.text = @"Waiting for initialization";
    self.logTextView = [[LiveLogTextView alloc] initWithAccessibilityLabel:@"First Look logs"];
    self.showButton = [DemoFlowLayout makeShowButton];
    [self.showButton addTarget:self action:@selector(showInterstitial) forControlEvents:UIControlEventTouchUpInside];
    self.retry = [[RetryScheduler alloc] init];
    [DemoFlowLayout installViews:@[self.initializationStatusLabel, self.interstitialStatusLabel, self.logTextView, self.showButton]
                          inView:self.view];

    __weak typeof(self) weakSelf = self;
    self.startup = [[DemoSdkStartup alloc] initWithStatusHandler:^(NSString *status) {
        weakSelf.initializationStatusLabel.text = status;
    } cloudXSettledHandler:^(BOOL cloudXAvailable) {
        [weakSelf createControllerWithCloudXAvailable:cloudXAvailable];
    }];
    [self.startup start];
}

- (void)createControllerWithCloudXAvailable:(BOOL)cloudXAvailable {
    if (self.controller) return;

    CloudXFirstLookSource *cloudXSource = nil;
    if (cloudXAvailable) {
        NSString *adUnitId = [CLXDemoConfigManager sharedManager].currentConfig.interstitialAdUnitId;
        cloudXSource = [[CloudXFirstLookSource alloc] initWithViewController:self adUnitId:adUnitId];
        if (!cloudXSource) {
            [[DemoAppLogger sharedInstance] logMessage:@"CloudX interstitial unavailable; AdMob only"];
        }
    }
    __weak typeof(self) weakSelf = self;
    FirstLookInterstitialController *newController = [[FirstLookInterstitialController alloc]
        initWithCloudX:cloudXSource
                 adMob:[[AdMobFirstLookSource alloc] initWithViewController:self adUnitId:AdMobDemoConfig.interstitialAdUnitId]
               onEvent:^(FirstLookEvent *event) {
        [weakSelf onInterstitialEvent:event];
    }];
    self.controller = newController;
    self.interstitialStatusLabel.text = @"Loading interstitial…";
    self.showButton.enabled = YES;
    [newController load];
}

- (void)showInterstitial {
    FirstLookSource source = self.controller ? [self.controller show] : FirstLookSourceNone;
    if (source != FirstLookSourceNone) {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Requested interstitial (%@)", NSStringFromFirstLookSource(source)]];
    } else if (self.retry.isPending) {
        // A tap must not skip the backoff of a retry that is already scheduled.
        self.interstitialStatusLabel.text = @"No ad ready; waiting for the scheduled retry";
    } else {
        self.interstitialStatusLabel.text = @"No ad ready; reloading";
        [self.controller load];
    }
}

- (void)onInterstitialEvent:(FirstLookEvent *)event {
    NSString *source = NSStringFromFirstLookSource(event.source);
    switch (event.type) {
        case FirstLookEventTypeLoaded:
            [self.retry reset];
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Loaded (%@)", source];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial loaded (%@)", source]];
            break;
        case FirstLookEventTypeLoadFailed:
            [self scheduleRetryWithMessage:[NSString stringWithFormat:@"Load failed (%@): %@", source, event.message]];
            break;
        case FirstLookEventTypeShown:
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Showing (%@)", source];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial shown (%@)", source]];
            break;
        case FirstLookEventTypeShowFailed:
            [self scheduleRetryWithMessage:[NSString stringWithFormat:@"Show failed (%@): %@", source, event.message]];
            break;
        case FirstLookEventTypeClosed:
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Closed (%@); loading next ad", source];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial closed (%@)", source]];
            [self.controller load];
            break;
        case FirstLookEventTypeClicked:
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial clicked (%@)", source]];
            break;
    }
}

- (void)scheduleRetryWithMessage:(NSString *)message {
    __weak typeof(self) weakSelf = self;
    NSInteger seconds = [self.retry scheduleAction:^{
        [weakSelf.controller load];
    }];
    self.interstitialStatusLabel.text = [NSString stringWithFormat:@"%@\nRetrying in %lds…", message, (long)seconds];
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"%@; retrying in %lds", message, (long)seconds]];
}

@end
