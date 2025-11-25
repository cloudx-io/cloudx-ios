#import "InitInternalViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXURLProvider.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "NSError+DemoDescription.h"

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
    self.title = @"ObjC Demo";
    
    CLXDemoConfigManager *configManager = [CLXDemoConfigManager sharedManager];
    if ([configManager isDebugBuild]) {
        [configManager setEnvironment:CLXDemoEnvironmentStaging];
    } else {
        [configManager setEnvironment:CLXDemoEnvironmentProduction];
    }
    
    [self setupEnvironmentButtons];
    
    // SDK initialization state tracked internally
    self.isSDKInitialized = NO; // Will be set to YES after successful initialization
    [self updateStatusUIWithCurrentEnvironment];
    [self updateButtonStates];
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
    [self updateButtonStates];
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
    
    // Create stack view for buttons - Staging at top, Dev, Production at bottom
    self.buttonStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.stagingButton, self.devButton, self.prodButton]];
    self.buttonStackView.axis = UILayoutConstraintAxisVertical;
    self.buttonStackView.spacing = 16;
    self.buttonStackView.alignment = UIStackViewAlignmentFill;
    self.buttonStackView.distribution = UIStackViewDistributionFillEqually;
    self.buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.buttonStackView];
    
    // Add constraints - button dimensions (200px wide, 44px tall)
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
    
    // Tag button with environment for identification
    button.tag = environment;
    
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

- (void)updateButtonStates {
    NSArray<UIButton *> *buttons = @[self.devButton, self.stagingButton, self.prodButton];
    
    for (UIButton *button in buttons) {
        CLXDemoEnvironment buttonEnvironment = (CLXDemoEnvironment)button.tag;
        
        // All environment buttons are now enabled regardless of build configuration
        // The SDK uses the environment override from CLXURLProvider internally
        button.enabled = YES;
        button.backgroundColor = [self colorForEnvironment:buttonEnvironment];
        button.alpha = 1.0;
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
    
    // Update button states to reflect the new environment
    [self updateButtonStates];
    
    CLXDemoConfig *config = [configManager currentConfig];
    NSString *environmentName = [configManager environmentName:environment];
    
    [self updateStatusUIWithState:AdStateLoading];
    
    // Clear DI container to force fresh services with new environment
    [[CLXDIContainer shared] reset];
    
    // Set environment using internal override key BEFORE SDK init
    // This controls which server (dev/staging/production) the SDK connects to
    NSString *environmentKey;
    switch (environment) {
        case CLXDemoEnvironmentDev:
            environmentKey = @"dev";
            break;
        case CLXDemoEnvironmentStaging:
            environmentKey = @"staging";
            break;
        case CLXDemoEnvironmentProduction:
            environmentKey = @"production";
            break;
    }
    
    // Set the internal environment override (production clears it to use default)
    [CLXURLProvider setEnvironment:environmentKey];
    
    // Set hashed user ID before initialization if provided
    if (config.hashedUserId.length > 0) {
        [[CloudXCore shared] setHashedUserID:config.hashedUserId];
    }
    
    // Determine test mode based on build configuration
    BOOL testMode = NO;
    #if TARGET_IPHONE_SIMULATOR
        testMode = YES;
    #elif DEBUG
        testMode = YES;
    #endif
    
    // Use standard CloudXCore initialization which will now use our environment override
    [[CloudXCore shared] initializeSDKWithAppKey:config.appKey 
                                        testMode:testMode
                                      completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ SDK initialized successfully with %@ environment", environmentName]];
            self.isSDKInitialized = YES;
            [self updateStatusUIWithState:AdStateReady];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
        } else {
            // Get detailed error description
            NSString *detailedError = error ? [error detailedDemoDescription] : @"Unknown error occurred";
            
            // Add environment-specific context
            NSString *enhancedError = [NSString stringWithFormat:@"Environment: %@\n\n%@", environmentName, detailedError];
            
            [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ SDK init failed: %@", detailedError]];
            [self updateStatusUIWithState:AdStateNoAd];
            [self showAlertWithTitle:@"SDK Initialization Failed" message:enhancedError];
        }
    }];
}

@end
