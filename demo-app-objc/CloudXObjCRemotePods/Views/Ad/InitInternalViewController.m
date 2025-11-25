#import "InitInternalViewController.h"
#import "CLXDemoConfigManager.h"
#import "BaseAdViewController.h"
#import "DemoAppLogger.h"
#import <CloudXCore/CloudXCore.h>

@interface InitInternalViewController ()
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, strong) UIButton *initializationButton;
@end

@implementation InitInternalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ObjC Demo";
    
    [self setupInitializationButton];
    
    self.isSDKInitialized = NO;
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)setupShowLogsButton {
    // Do nothing - no show logs button for InitInternalViewController
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)setupInitializationButton {
    // Create initialization button
    self.initializationButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.initializationButton setTitle:@"Initialize SDK" forState:UIControlStateNormal];
    [self.initializationButton addTarget:self action:@selector(initializeSDK) forControlEvents:UIControlEventTouchUpInside];
    
    // Style the button
    self.initializationButton.backgroundColor = [UIColor systemBlueColor];
    [self.initializationButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.initializationButton.layer.cornerRadius = 8;
    self.initializationButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.initializationButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.initializationButton];
    
    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.initializationButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.initializationButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.initializationButton.widthAnchor constraintEqualToConstant:200],
        [self.initializationButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)initializeSDK {
    if (self.isSDKInitialized) {
        [self showAlertWithTitle:@"SDK Already Initialized" message:@"The SDK is already initialized."];
        return;
    }
    
    [self updateStatusUIWithState:AdStateLoading];
    self.initializationButton.enabled = NO;
    
    CLXDemoConfig *config = [[CLXDemoConfigManager sharedManager] currentConfig];
    
    [[DemoAppLogger sharedInstance] logMessage:@"Initializing SDK"];
    
    // Set hashed user ID before initialization if provided
    if (config.hashedUserId.length > 0) {
        [[CloudXCore shared] setHashedUserID:config.hashedUserId];
    }
    
    // Use standard CloudXCore initialization
    // Production demo app - use testMode:NO for real ads
    [[CloudXCore shared] initializeSDKWithAppKey:config.appKey 
                                testMode:NO
                                completion:^(BOOL success, CLXError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [[DemoAppLogger sharedInstance] logMessage:@"✅ SDK initialized successfully"];
                self.isSDKInitialized = YES;
                [self updateStatusUIWithState:AdStateReady];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
            } else {
                NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
                [self showAlertWithTitle:@"SDK Init Failed" message:errorMessage];
                [self updateStatusUIWithState:AdStateNoAd];
                self.initializationButton.enabled = YES;
                [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ SDK init failed: %@", errorMessage]];
            }
        });
    }];
}

@end
