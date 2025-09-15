#import "InitViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"


@interface InitViewController ()
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@end

@implementation InitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ObjC Demo";
    [self setupCenteredButtonWithTitle:@"Initialize SDK" action:@selector(initializeSDK)];
    
    // Set default environment to Development for external InitViewController
    [[CLXDemoConfigManager sharedManager] setEnvironment:CLXDemoEnvironmentDev];
    
    // Check if SDK is already initialized
    self.isSDKInitialized = [[CloudXCore shared] isInitialised];
    self.settings = [UserDefaultsSettings sharedSettings];
    [self updateStatusUIWithState:self.isSDKInitialized ? AdStateReady : AdStateNoAd];
}

// Override to prevent show logs button from appearing in InitViewController
- (void)setupShowLogsButton {
    // Do nothing - no show logs button for InitViewController
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    // Update UI if SDK is already initialized
    if (self.isSDKInitialized) {
        [self updateStatusUIWithState:AdStateReady];
    }
}

// Override to provide SDK-specific status messages instead of ad-related ones
- (void)updateStatusUIWithState:(AdState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text;
        UIColor *color;
        
        switch (state) {
            case AdStateNoAd:
                text = @"SDK Not Initialized";
                color = [UIColor systemRedColor];
                break;
            case AdStateLoading:
                text = @"SDK Initializing...";
                color = [UIColor systemYellowColor];
                break;
            case AdStateReady:
                text = @"SDK Initialized";
                color = [UIColor systemGreenColor];
                break;
        }
        
        self.statusLabel.text = text;
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
}

- (void)initializeSDK {
    if (self.isSDKInitialized) {
        [self showAlertWithTitle:@"SDK Already Initialized" message:@"The SDK is already initialized."];
        return;
    }
    
    [self updateStatusUIWithState:AdStateLoading];
    
    CLXDemoConfig *config = [[CLXDemoConfigManager sharedManager] currentConfig];
    
    NSString *appId = config.appId;
    
    if (_settings.bannerPlacement.length > 0) {
        appId = _settings.appKey;
    }
    [[CloudXCore shared] initSDKWithAppKey:appId
                              hashedUserID:config.hashedUserId
                                completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [[DemoAppLogger sharedInstance] logMessage:@"SDK initialized successfully"];
            self.isSDKInitialized = YES;
            [self updateStatusUIWithState:AdStateReady];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
        } else {
            NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
            [self showAlertWithTitle:@"SDK Init Failed" message:errorMessage];
        }
    }];
}


@end
