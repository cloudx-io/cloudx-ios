#import "InitInternalViewController.h"
#import "CLXDemoConfigManager.h"
#import "BaseAdViewController.h"
#import "DemoAppLogger.h"
#import <CloudXCore/CloudXCore.h>

@interface InitInternalViewController ()
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, strong) UIButton *initButton;
@end

@implementation InitInternalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ObjC Demo";
    
    [self setupInitButton];
    
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

- (void)setupInitButton {
    // Create init button
    self.initButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.initButton setTitle:@"Init SDK" forState:UIControlStateNormal];
    [self.initButton addTarget:self action:@selector(initializeSDK) forControlEvents:UIControlEventTouchUpInside];
    
    // Style the button
    self.initButton.backgroundColor = [UIColor systemBlueColor];
    [self.initButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.initButton.layer.cornerRadius = 8;
    self.initButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.initButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.initButton];
    
    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.initButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.initButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.initButton.widthAnchor constraintEqualToConstant:200],
        [self.initButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)initializeSDK {
    if (self.isSDKInitialized) {
        [self showAlertWithTitle:@"SDK Already Initialized" message:@"The SDK is already initialized."];
        return;
    }
    
    [self updateStatusUIWithState:AdStateLoading];
    self.initButton.enabled = NO;
    
    CLXDemoConfig *config = [[CLXDemoConfigManager sharedManager] currentConfig];
    
    [[DemoAppLogger sharedInstance] logMessage:@"Initializing SDK"];
    
    // Set hashed user ID before initialization if provided
    if (config.hashedUserId.length > 0) {
        [[CloudXCore shared] setHashedUserID:config.hashedUserId];
    }
    
    // Use standard CloudXCore initialization
    [[CloudXCore shared] initializeSDKWithAppKey:config.appKey 
                                completion:^(BOOL success, NSError * _Nullable error) {
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
                self.initButton.enabled = YES;
                [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ SDK init failed: %@", errorMessage]];
            }
        });
    }];
}

@end
