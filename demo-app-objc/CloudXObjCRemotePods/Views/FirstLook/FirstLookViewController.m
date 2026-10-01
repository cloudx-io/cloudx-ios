#import "FirstLookViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "AdMobFirstLookSource.h"
#import "AppTrackingPermission.h"
#import "CLXDemoConfigManager.h"
#import "CloudXFirstLookSource.h"
#import "DemoAppLogger.h"
#import "FirstLookInterstitialController.h"

/*
 * Google's test interstitial for iOS. Replace it, and the GADApplicationIdentifier in
 * Info.plist, with your own IDs before using this flow in a production app.
 */
static NSString * const kAdMobInterstitialAdUnitId = @"ca-app-pub-3940256099942544/4411468910";
static NSTimeInterval const kInitializationTimeout = 15;
static NSTimeInterval const kRetryBaseDelay = 2;
static NSTimeInterval const kRetryMaxDelay = 60;
static NSInteger const kRetryMaxShift = 5;
// Same bound as DemoAppLogger, so a screen left open through the retry loop cannot grow without limit.
static NSUInteger const kLogLineLimit = 500;

@interface FirstLookViewController ()
@property (nonatomic, strong) UILabel *initializationStatusLabel;
@property (nonatomic, strong) UILabel *interstitialStatusLabel;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, copy) NSString *cloudXStatus;
@property (nonatomic, copy) NSString *adMobStatus;
@property (nonatomic, strong, nullable) FirstLookInterstitialController *controller;
@property (nonatomic, copy, nullable) dispatch_block_t initializationTimeoutWork;
@property (nonatomic, copy, nullable) dispatch_block_t retryWork;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic, strong) NSMutableArray<NSString *> *logLines;
@property (nonatomic, strong, nullable) id<NSObject> logObserver;
@end

@implementation FirstLookViewController

- (void)dealloc {
    if (_initializationTimeoutWork) dispatch_block_cancel(_initializationTimeoutWork);
    if (_retryWork) dispatch_block_cancel(_retryWork);
    [_controller dispose];
    if (_logObserver) [[NSNotificationCenter defaultCenter] removeObserver:_logObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"First Look";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.cloudXStatus = @"CloudX: Initializing";
    self.adMobStatus = @"AdMob: Initializing";
    self.logLines = [NSMutableArray array];
    [self setupViews];
    [self publishInitializationStatus];
    self.interstitialStatusLabel.text = @"Waiting for initialization";
    [self observeLogs];

    [self initializeAdMob];
    __weak typeof(self) weakSelf = self;
    [AppTrackingPermission requestWithCompletion:^{
        [weakSelf initializeCloudX];
    }];
}

- (void)setupViews {
    self.initializationStatusLabel = [[UILabel alloc] init];
    self.interstitialStatusLabel = [[UILabel alloc] init];
    for (UILabel *label in @[self.initializationStatusLabel, self.interstitialStatusLabel]) {
        label.font = [UIFont systemFontOfSize:15];
        label.numberOfLines = 0;
    }

    self.logTextView = [[UITextView alloc] init];
    self.logTextView.editable = NO;
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.logTextView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.logTextView.layer.cornerRadius = 8;
    self.logTextView.accessibilityLabel = @"First Look logs";

    self.showButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.showButton setTitle:@"Show Interstitial" forState:UIControlStateNormal];
    self.showButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.showButton.enabled = NO;
    [self.showButton addTarget:self action:@selector(showInterstitial) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.initializationStatusLabel, self.interstitialStatusLabel, self.logTextView, self.showButton
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:12],
        [stack.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-12],
        [stack.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-12],
        [self.showButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

/*
 * Shows every demo log line as it is written, so the screen shows what the sources report.
 * Keeps the last kLogLineLimit lines and re-renders from that buffer.
 */
- (void)observeLogs {
    __weak typeof(self) weakSelf = self;
    self.logObserver = [[NSNotificationCenter defaultCenter] addObserverForName:DemoAppLoggerDidAppendEntryNotification
                                                                         object:nil
                                                                          queue:[NSOperationQueue mainQueue]
                                                                     usingBlock:^(NSNotification *notification) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        DemoAppLogEntry *entry = notification.userInfo[DemoAppLoggerEntryUserInfoKey];
        if (!strongSelf || ![entry isKindOfClass:[DemoAppLogEntry class]]) return;
        [strongSelf.logLines addObject:[NSString stringWithFormat:@"%@ %@", entry.formattedTimestamp, entry.message]];
        if (strongSelf.logLines.count > kLogLineLimit) {
            [strongSelf.logLines removeObjectsInRange:NSMakeRange(0, strongSelf.logLines.count - kLogLineLimit)];
        }
        strongSelf.logTextView.text = [strongSelf.logLines componentsJoinedByString:@"\n"];
        [strongSelf.logTextView scrollRangeToVisible:NSMakeRange(strongSelf.logTextView.text.length, 0)];
    }];
}

/*
 * Loads do not wait for this. Google asks apps to wait for the completion handler only when they
 * use AdMob mediation, which this fallback does not.
 */
- (void)initializeAdMob {
    __weak typeof(self) weakSelf = self;
    [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.adMobStatus = @"AdMob: Ready";
            [strongSelf publishInitializationStatus];
        });
    }];
}

/** Waits up to 15 s for the CloudX answer, then continues with AdMob only. */
- (void)initializeCloudX {
    CLXDemoConfig *config = [CLXDemoConfigManager sharedManager].currentConfig;
    if (config.hashedUserId.length > 0) {
        [[CloudXCore shared] setHashedUserID:config.hashedUserId];
    }
    [[DemoAppLogger sharedInstance] logMessage:@"Initializing CloudX SDK"];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t timeoutWork = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.controller) return;
        strongSelf.cloudXStatus = @"CloudX: No response, AdMob only";
        [strongSelf publishInitializationStatus];
        [strongSelf createControllerWithCloudXAvailable:NO];
    });
    self.initializationTimeoutWork = timeoutWork;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kInitializationTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), timeoutWork);

    CLXInitializationConfiguration *initConfig = [CLXInitializationConfiguration configurationWithAppKey:config.appKey];
    [[CloudXCore shared] initializeWithConfiguration:initConfig
                                          completion:^(CLXSdkConfiguration * _Nullable sdkConfig, CLXError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            if (sdkConfig) {
                [[DemoAppLogger sharedInstance] logMessage:@"CloudX SDK initialized"];
                strongSelf.cloudXStatus = strongSelf.controller == nil
                    ? @"CloudX: Initialized"
                    : @"CloudX: Initialized late, AdMob only";
                [strongSelf publishInitializationStatus];
                [strongSelf createControllerWithCloudXAvailable:YES];
            } else {
                NSString *message = error.localizedDescription ?: @"Unknown error";
                [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"CloudX SDK initialization failed: %@", message]];
                strongSelf.cloudXStatus = [NSString stringWithFormat:@"CloudX: Failed (%@)", message];
                [strongSelf publishInitializationStatus];
                [strongSelf createControllerWithCloudXAvailable:NO];
            }
        });
    }];
}

- (void)createControllerWithCloudXAvailable:(BOOL)cloudXAvailable {
    if (self.controller) return;
    if (self.initializationTimeoutWork) {
        dispatch_block_cancel(self.initializationTimeoutWork);
        self.initializationTimeoutWork = nil;
    }

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
                 adMob:[[AdMobFirstLookSource alloc] initWithViewController:self adUnitId:kAdMobInterstitialAdUnitId]
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
    } else if (self.retryWork) {
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
            if (self.retryWork) {
                dispatch_block_cancel(self.retryWork);
                self.retryWork = nil;
            }
            self.retryCount = 0;
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

/*
 * Retry policy after a load or show failure: 2 s, 4 s, 8 s and so on up to 60 s, reset by the
 * next successful load. A fixed short delay would turn sustained no-fill into a tight request
 * loop against the fallback network.
 */
- (void)scheduleRetryWithMessage:(NSString *)message {
    NSTimeInterval delay = MIN(kRetryBaseDelay * (1 << self.retryCount), kRetryMaxDelay);
    self.retryCount = MIN(self.retryCount + 1, kRetryMaxShift);
    NSInteger seconds = (NSInteger)delay;
    self.interstitialStatusLabel.text = [NSString stringWithFormat:@"%@\nRetrying in %lds…", message, (long)seconds];
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"%@; retrying in %lds", message, (long)seconds]];
    if (self.retryWork) {
        dispatch_block_cancel(self.retryWork);
    }
    __weak typeof(self) weakSelf = self;
    dispatch_block_t work = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.retryWork = nil;
        [strongSelf.controller load];
    });
    self.retryWork = work;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), work);
}

- (void)publishInitializationStatus {
    self.initializationStatusLabel.text = [NSString stringWithFormat:@"%@ | %@", self.cloudXStatus, self.adMobStatus];
}

@end
