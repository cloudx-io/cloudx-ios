#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import "BaseAdViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "LogsModalViewController.h"
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "DemoToastView.h"

@implementation BaseAdViewController

- (NSString *)appKey {
    return [[CLXDemoConfigManager sharedManager] currentConfig].appKey;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupStatusUI];
    [self setupShowLogsButton];
    [self updateStatusUIWithState:AdStateNoAd];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Clear logs when switching between different ad formats (tabs)
    NSString *currentAdFormat = NSStringFromClass([self class]);
    static NSString *lastAdFormat = nil;
    
    if (lastAdFormat && ![lastAdFormat isEqualToString:currentAdFormat]) {
        // Switching between different ad formats - clear logs for clean slate
        [[DemoAppLogger sharedInstance] clearLogs];
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"[%@] Switched from %@ - logs cleared", currentAdFormat, lastAdFormat]];
    }
    // No log for same format - keep it clean
    
    // Remember current ad format for next time (session only)
    lastAdFormat = currentAdFormat;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Don't clear logs when leaving - let user see the complete ad lifecycle
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    NSString *safeTitle = title ?: @"Alert";
    NSString *safeMessage = message ?: @"";
    [DemoToastView showInViewController:self title:safeTitle message:safeMessage];
}

- (void)initializeSDKWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    NSString *appKey = [self appKey];
    if (!appKey || [appKey length] == 0) {
        if (completion) completion(NO, [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"API key is missing."}]);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLXDemoConfig *config = [[CLXDemoConfigManager sharedManager] currentConfig];
        NSString *hashedUserId = config.hashedUserId;
        
        // Set hashed user ID before initialization if provided
        if (hashedUserId.length > 0) {
            [[CloudXCore shared] setHashedUserID:hashedUserId];
        }
        
        [self updateStatusUIWithState:AdStateLoading];
        // Use standard CloudXCore initialization with configuration object
        CLXInitializationConfiguration *initConfig = [CLXInitializationConfiguration configurationWithAppKey:appKey];
        [[CloudXCore shared] initializeWithConfiguration:initConfig completion:^(CLXSdkConfiguration * _Nullable sdkConfig, CLXError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL success = (sdkConfig != nil);
                if (success) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
                }
                if (completion) completion(success, error);
            });
        }];
    });
}

- (void)initializeSDK {
    [self initializeSDKWithCompletion:^(BOOL success, NSError * _Nullable error) {
        // No action needed for this convenience method
    }];
}

- (void)updateStatusUIWithState:(AdState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text;
        UIColor *color;
        
        switch (state) {
            case AdStateNoAd:
                text = @"No Ad Loaded";
                color = [UIColor systemRedColor];
                break;
            case AdStateLoading:
                text = @"Loading Ad...";
                color = [UIColor systemYellowColor];
                break;
            case AdStateReady:
                text = @"Ad Ready";
                color = [UIColor systemGreenColor];
                break;
        }
        
        self.statusLabel.text = text;
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
}

- (void)setupStatusUI {
    // Setup status indicator stack
    self.statusStack = [[UIStackView alloc] init];
    self.statusStack.axis = UILayoutConstraintAxisHorizontal;
    self.statusStack.spacing = 8;
    self.statusStack.alignment = UIStackViewAlignmentCenter;
    self.statusStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.statusIndicator = [[UIView alloc] init];
    self.statusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusIndicator.layer.cornerRadius = 6;
    self.statusIndicator.clipsToBounds = YES;
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.statusStack addArrangedSubview:self.statusIndicator];
    [self.statusStack addArrangedSubview:self.statusLabel];
    
    [self.view addSubview:self.statusStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.statusStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.statusStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.statusIndicator.widthAnchor constraintEqualToConstant:12],
        [self.statusIndicator.heightAnchor constraintEqualToConstant:12]
    ]];
}

- (void)setupCenteredButtonWithTitle:(NSString *)title action:(SEL)action {
    if (!title) title = @"Button";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Use UIButtonConfiguration for iOS 15+ to avoid deprecated contentEdgeInsets
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *config = [UIButtonConfiguration filledButtonConfiguration];
        config.title = title;
        config.baseBackgroundColor = [UIColor systemBlueColor];
        config.baseForegroundColor = [UIColor whiteColor];
        config.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        config.contentInsets = NSDirectionalEdgeInsetsMake(12, 24, 12, 24);
        button.configuration = config;
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        button.contentEdgeInsets = UIEdgeInsetsMake(12, 24, 12, 24);
        #pragma clang diagnostic pop
    }
    
    if (action) {
        [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view addSubview:button];
    
    [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [button.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [button.widthAnchor constraintEqualToConstant:200],
        [button.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)setupShowLogsButton {
    // App Logs button (shows demo app logs)
    UIButton *showLogsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showLogsButton setTitle:@"App Logs" forState:UIControlStateNormal];
    showLogsButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    showLogsButton.backgroundColor = [UIColor systemOrangeColor];
    [showLogsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showLogsButton.layer.cornerRadius = 6;
    showLogsButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [showLogsButton addTarget:self action:@selector(showLogsModal) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:showLogsButton];
    
    // SDK Debugger button (toggles visual debugging)
    self.sdkDebuggerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self updateSDKDebuggerButtonTitle];
    self.sdkDebuggerButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.sdkDebuggerButton.layer.cornerRadius = 6;
    self.sdkDebuggerButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.sdkDebuggerButton addTarget:self action:@selector(toggleSDKDebugger) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.sdkDebuggerButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [showLogsButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [showLogsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [showLogsButton.widthAnchor constraintEqualToConstant:100],
        [showLogsButton.heightAnchor constraintEqualToConstant:32],
        
        [self.sdkDebuggerButton.topAnchor constraintEqualToAnchor:showLogsButton.bottomAnchor constant:8],
        [self.sdkDebuggerButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.sdkDebuggerButton.widthAnchor constraintEqualToConstant:100],
        [self.sdkDebuggerButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)updateSDKDebuggerButtonTitle {
    BOOL isEnabled = [CloudXCore isVisualDebuggingEnabled];
    if (isEnabled) {
        [self.sdkDebuggerButton setTitle:@"Debugger ✓" forState:UIControlStateNormal];
        self.sdkDebuggerButton.backgroundColor = [UIColor systemGreenColor];
    } else {
        [self.sdkDebuggerButton setTitle:@"Debugger" forState:UIControlStateNormal];
        self.sdkDebuggerButton.backgroundColor = [UIColor systemPurpleColor];
    }
    [self.sdkDebuggerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)toggleSDKDebugger {
    BOOL currentState = [CloudXCore isVisualDebuggingEnabled];
    [CloudXCore setVisualDebuggingEnabled:!currentState];
    [self updateSDKDebuggerButtonTitle];
}

- (void)showLogsModal {
    LogsModalViewController *logsModal = [[LogsModalViewController alloc] initWithTitle:@"Demo App Logs"];
    logsModal.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentViewController:logsModal animated:YES completion:nil];
}


@end 
