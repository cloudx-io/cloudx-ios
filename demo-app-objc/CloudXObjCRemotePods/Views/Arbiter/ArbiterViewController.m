#import "ArbiterViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "AdMobDemoConfig.h"
#import "ArbiterInterstitialController.h"
#import "CLXDemoConfigManager.h"
#import "DemoAppLogger.h"
#import "DemoFlowLayout.h"
#import "DemoSdkStartup.h"
#import "LiveLogTextView.h"
#import "RetryScheduler.h"

@interface ArbiterViewController ()
@property (nonatomic, strong) UILabel *initializationStatusLabel;
@property (nonatomic, strong) UILabel *roundStatusLabel;
@property (nonatomic, strong) UILabel *interstitialStatusLabel;
@property (nonatomic, strong) UILabel *revenueStatusLabel;
@property (nonatomic, strong) LiveLogTextView *logTextView;
@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, strong) RetryScheduler *retry;
@property (nonatomic, strong, nullable) DemoSdkStartup *startup;
@property (nonatomic, strong, nullable) ArbiterInterstitialController *controller;
@end

@implementation ArbiterViewController

- (void)dealloc {
    [_controller dispose];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Arbiter/TPA";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.initializationStatusLabel = [DemoFlowLayout makeStatusLabel];
    self.roundStatusLabel = [DemoFlowLayout makeStatusLabel];
    self.roundStatusLabel.text = @"Arbiter: not run yet";
    self.interstitialStatusLabel = [DemoFlowLayout makeStatusLabel];
    self.interstitialStatusLabel.text = @"Waiting for initialization";
    self.revenueStatusLabel = [DemoFlowLayout makeStatusLabel];
    self.revenueStatusLabel.text = @"Revenue -> CloudX: no AdMob paid event yet";
    self.logTextView = [[LiveLogTextView alloc] initWithAccessibilityLabel:@"Arbiter/TPA logs"];
    self.showButton = [DemoFlowLayout makeShowButton];
    [self.showButton addTarget:self action:@selector(showInterstitial) forControlEvents:UIControlEventTouchUpInside];
    self.retry = [[RetryScheduler alloc] init];
    [DemoFlowLayout installViews:@[
        self.initializationStatusLabel, self.roundStatusLabel, self.interstitialStatusLabel, self.revenueStatusLabel,
        self.logTextView, self.showButton
    ] inView:self.view];

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
    __weak typeof(self) weakSelf = self;
    ArbiterInterstitialController *newController = [[ArbiterInterstitialController alloc]
        initWithViewController:self
                cloudXAdUnitId:[CLXDemoConfigManager sharedManager].currentConfig.arbiterInterstitialAdUnitId
                 adMobAdUnitId:AdMobDemoConfig.interstitialAdUnitId
    adMobManualRevenuePerImpressionUSD:AdMobDemoConfig.manualRevenuePerImpressionUSD
               cloudXAvailable:cloudXAvailable
                       onEvent:^(ArbiterEvent *event) {
        [weakSelf onArbiterEvent:event];
    }];
    self.controller = newController;
    self.interstitialStatusLabel.text = @"Loading CloudX and AdMob…";
    self.showButton.enabled = YES;
    [newController load];
}

- (void)showInterstitial {
    ArbiterInterstitialController *controller = self.controller;
    if (!controller) return;
    CLXArbiterPlatform *platform = [controller show];
    if (platform) {
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Requested interstitial (%@)", platform.name]];
    } else if (controller.isShowing) {
        return;
    } else if (controller.isBusy) {
        // A load or a round is still running, and its result will update the status lines.
        self.roundStatusLabel.text = @"Arbiter: round in progress";
    } else if (self.retry.isPending) {
        // A tap must not skip the backoff of a retry that is already scheduled.
        self.interstitialStatusLabel.text = @"No winner prepared; waiting for the scheduled retry";
    } else {
        /*
         * A real app carries on without an ad here. The demo reloads so that the next tap has a
         * winner to show.
         */
        self.interstitialStatusLabel.text = @"No winner prepared; reloading";
        [controller load];
    }
}

- (void)onArbiterEvent:(ArbiterEvent *)event {
    NSString *platform = event.platform.name;
    switch (event.type) {
        case ArbiterEventTypeLoaded:
            [self.retry reset];
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Loaded (%@)", platform];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial loaded (%@)", platform]];
            break;
        case ArbiterEventTypeLoadFailed:
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Load failed (%@): %@", platform, event.message];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial failed to load (%@): %@", platform, event.message]];
            break;
        case ArbiterEventTypeArbiterCompleted: {
            NSString *bids = event.bidCount == 1 ? @"1 bid" : [NSString stringWithFormat:@"%ld bids", (long)event.bidCount];
            self.roundStatusLabel.text = [platform isEqualToString:CLXArbiterPlatform.none.name]
                ? [NSString stringWithFormat:@"Arbiter: no winner (%@)", bids]
                : [NSString stringWithFormat:@"Arbiter: %@ (%@)", platform, bids];
            break;
        }
        case ArbiterEventTypeNoCandidates:
            self.roundStatusLabel.text = @"Arbiter: no candidates, nothing to arbitrate";
            [self scheduleRetryWithMessage:@"Neither platform filled"];
            break;
        case ArbiterEventTypeShown:
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Showing (%@)", platform];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial shown (%@)", platform]];
            break;
        case ArbiterEventTypeShowFailed:
            [self scheduleRetryWithMessage:[NSString stringWithFormat:@"Show failed (%@): %@", platform, event.message]];
            break;
        case ArbiterEventTypeClosed:
            self.interstitialStatusLabel.text = [NSString stringWithFormat:@"Closed (%@); loading the next round", platform];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial closed (%@)", platform]];
            [self.controller load];
            break;
        case ArbiterEventTypeClicked:
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Interstitial clicked (%@)", platform]];
            break;
        case ArbiterEventTypeRevenueReported:
            self.revenueStatusLabel.text = [NSString stringWithFormat:@"Revenue -> CloudX: %.6f %@ (accepted=%@)",
                                            event.revenue, event.currencyCode, event.accepted ? @"true" : @"false"];
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
