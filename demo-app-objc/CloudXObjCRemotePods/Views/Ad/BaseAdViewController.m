#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import "BaseAdViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import "LogsModalViewController.h"
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"

@implementation BaseAdViewController

- (NSString *)appKey {
    return [[CLXDemoConfigManager sharedManager] currentConfig].appId;
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
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:safeTitle
                                                                     message:safeMessage
                                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
            // No action needed
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
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
        [self updateStatusUIWithState:AdStateLoading];
        [[CloudXCore shared] initSDKWithAppKey:appKey hashedUserID:hashedUserId completion:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
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
    UIButton *showLogsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [showLogsButton setTitle:@"Show Logs" forState:UIControlStateNormal];
    showLogsButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    showLogsButton.backgroundColor = [UIColor systemOrangeColor];
    [showLogsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    showLogsButton.layer.cornerRadius = 6;
    showLogsButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [showLogsButton addTarget:self action:@selector(showLogsModal) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:showLogsButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [showLogsButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [showLogsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [showLogsButton.widthAnchor constraintEqualToConstant:100],
        [showLogsButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)showLogsModal {
    LogsModalViewController *logsModal = [[LogsModalViewController alloc] initWithTitle:@"Logs"];
    logsModal.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self presentViewController:logsModal animated:YES completion:nil];
}


@end 
