#import "InitInternalViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "CLXLiveInitService+Internal.h"

@interface InitInternalViewController ()
@property (nonatomic, assign) BOOL isSDKInitialized;
@property (nonatomic, strong) UIStackView *buttonStackView;
@property (nonatomic, strong) UIButton *devButton;
@property (nonatomic, strong) UIButton *stagingButton;
@property (nonatomic, strong) UIButton *prodButton;
@end

@implementation InitInternalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Internal Init";
    [self setupEnvironmentButtons];
    
    // Check if SDK is already initialized
    self.isSDKInitialized = [[CloudXCore shared] isInitialised];
    [self updateStatusUIWithCurrentEnvironment];
}

// Override to prevent show logs button from appearing in InitInternalViewController
- (void)setupShowLogsButton {
    // Do nothing - no show logs button for InitInternalViewController
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    // Update UI if SDK is already initialized
    if (self.isSDKInitialized) {
        [self updateStatusUIWithCurrentEnvironment];
    }
}

- (void)setupEnvironmentButtons {
    // Create buttons
    self.devButton = [self createButtonWithTitle:@"Init Dev" 
                                          action:@selector(initializeWithDevEnvironment)
                                     environment:CLXDemoEnvironmentDev];
    
    self.stagingButton = [self createButtonWithTitle:@"Init Staging" 
                                              action:@selector(initializeWithStagingEnvironment)
                                         environment:CLXDemoEnvironmentStaging];
    
    self.prodButton = [self createButtonWithTitle:@"Init Production" 
                                            action:@selector(initializeWithProductionEnvironment)
                                       environment:CLXDemoEnvironmentProduction];
    
    // Create stack view for buttons - Staging at top, Dev in middle, Production at bottom
    self.buttonStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.stagingButton, self.devButton, self.prodButton]];
    self.buttonStackView.axis = UILayoutConstraintAxisVertical;
    self.buttonStackView.spacing = 16;
    self.buttonStackView.alignment = UIStackViewAlignmentFill;
    self.buttonStackView.distribution = UIStackViewDistributionFillEqually;
    self.buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.buttonStackView];
    
    // Add constraints - match InitViewController button dimensions (200px wide, 44px tall)
    [NSLayoutConstraint activateConstraints:@[
        [self.buttonStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.buttonStackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.stagingButton.widthAnchor constraintEqualToConstant:200],
        [self.stagingButton.heightAnchor constraintEqualToConstant:44],
        [self.devButton.widthAnchor constraintEqualToConstant:200],
        [self.devButton.heightAnchor constraintEqualToConstant:44],
        [self.prodButton.widthAnchor constraintEqualToConstant:200],
        [self.prodButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action environment:(CLXDemoEnvironment)environment {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    // Style the button
    button.backgroundColor = [self colorForEnvironment:environment];
    button.tintColor = [UIColor whiteColor];
    button.layer.cornerRadius = 8;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    
    return button;
}

- (UIColor *)colorForEnvironment:(CLXDemoEnvironment)environment {
    switch (environment) {
        case CLXDemoEnvironmentDev:
            return [UIColor systemBlueColor];
        case CLXDemoEnvironmentStaging:
            // Light blue - not too bright or light
            return [UIColor colorWithRed:0.4 green:0.7 blue:0.9 alpha:1.0];
        case CLXDemoEnvironmentProduction:
            // Green - not too bright or light
            return [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1.0];
    }
}

// Override to provide environment-specific status messages
- (void)updateStatusUIWithCurrentEnvironment {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text;
        UIColor *color;
        
        CLXDemoConfigManager *configManager = [CLXDemoConfigManager sharedManager];
        NSString *environmentName = [configManager environmentName:configManager.currentEnvironment];
        
        if (self.isSDKInitialized) {
            text = [NSString stringWithFormat:@"SDK Initialized (%@)", environmentName];
            color = [UIColor systemGreenColor];
        } else {
            text = [NSString stringWithFormat:@"SDK Not Initialized (%@)", environmentName];
            color = [UIColor systemRedColor];
        }
        
        self.statusLabel.text = text;
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
}

- (void)updateStatusUIWithState:(AdState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text;
        UIColor *color;
        
        CLXDemoConfigManager *configManager = [CLXDemoConfigManager sharedManager];
        NSString *environmentName = [configManager environmentName:configManager.currentEnvironment];
        
        switch (state) {
            case AdStateNoAd:
                text = [NSString stringWithFormat:@"SDK Not Initialized (%@)", environmentName];
                color = [UIColor systemRedColor];
                break;
            case AdStateLoading:
                text = [NSString stringWithFormat:@"SDK Initializing (%@)...", environmentName];
                color = [UIColor systemYellowColor];
                break;
            case AdStateReady:
                text = [NSString stringWithFormat:@"SDK Initialized (%@)", environmentName];
                color = [UIColor systemGreenColor];
                break;
        }
        
        self.statusLabel.text = text;
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
}

- (void)initializeWithDevEnvironment {
    [self initializeWithEnvironment:CLXDemoEnvironmentDev];
}

- (void)initializeWithStagingEnvironment {
    [self initializeWithEnvironment:CLXDemoEnvironmentStaging];
}

- (void)initializeWithProductionEnvironment {
    [self initializeWithEnvironment:CLXDemoEnvironmentProduction];
}

- (void)initializeWithEnvironment:(CLXDemoEnvironment)environment {
    if (self.isSDKInitialized) {
        CLXDemoConfigManager *configManager = [CLXDemoConfigManager sharedManager];
        NSString *environmentName = [configManager environmentName:environment];
        [self showAlertWithTitle:@"SDK Already Initialized" 
                         message:[NSString stringWithFormat:@"The SDK is already initialized. Current environment: %@", 
                                 [configManager environmentName:configManager.currentEnvironment]]];
        return;
    }
    
    // Set the environment in config manager
    CLXDemoConfigManager *configManager = [CLXDemoConfigManager sharedManager];
    [configManager setEnvironment:environment];
    
    CLXDemoConfig *config = [configManager currentConfig];
    NSString *environmentName = [configManager environmentName:environment];
    
    [self updateStatusUIWithState:AdStateLoading];
    
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Initializing SDK with %@ environment", environmentName]];
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"AppId: %@", config.appId]];
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"HashedUserId: %@", config.hashedUserId]];
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"BaseURL: %@", config.baseURL]];
    
    // Use internal method to initialize with custom URL for proper environment testing
    CLXLiveInitService *liveInitService = [[CLXLiveInitService alloc] init];
    
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Using internal init method with custom URL: %@", config.baseURL]];
    
    [liveInitService initSDKWithAppKey:config.appId 
                         customInitURL:config.baseURL 
                            completion:^(CLXSDKConfigResponse * _Nullable sdkConfig, NSError * _Nullable configError) {
        if (sdkConfig && !configError) {
            // Config fetch successful! For demo purposes, this is sufficient.
            // We don't call the main SDK init to avoid the duplicate network call with wrong URL.
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Internal SDK init successful with %@ environment", environmentName]];
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"📊 Config fetched - Session: %@, Account: %@", sdkConfig.sessionID ?: @"N/A", sdkConfig.accountID ?: @"N/A"]];
            [[DemoAppLogger sharedInstance] logMessage:@"🎯 Demo app can now test ad loading with this config"];
            
            self.isSDKInitialized = YES;
            [self updateStatusUIWithState:AdStateReady];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
        } else {
            NSString *errorMessage = configError ? configError.localizedDescription : @"Unknown error occurred during config fetch";
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Internal SDK init failed: %@", errorMessage]];
            [self updateStatusUIWithState:AdStateNoAd];
            [self showAlertWithTitle:@"SDK Init Failed" message:errorMessage];
        }
    }];
}

@end
