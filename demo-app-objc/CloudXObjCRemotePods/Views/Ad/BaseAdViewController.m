#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import "BaseAdViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@implementation BaseAdViewController

- (NSString *)appKey {
//    return @"1c3589a1-rgto-4573-zdae-644c65074537";
//    return @"JP61DHwkf7zPcDN_lrt32";
//    return @"BwWU3Z8kHZrnAx-cBPMHw";
//    return @"qT9U-tJ0FRb0x4gXb-pF0";
    return @"g0PdN9_0ilfIcuNXhBopl";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"[BaseAdViewController] viewDidLoad");
    [self setupStatusUI];
    [self updateStatusUIWithState:AdStateNoAd];
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
    NSLog(@"[BaseAdViewController] initializeSDKWithCompletion called");
    NSString *appKey = [self appKey];
    if (!appKey || [appKey length] == 0) {
        if (completion) completion(NO, [NSError errorWithDomain:@"CloudX" code:1 userInfo:@{NSLocalizedDescriptionKey: @"API key is missing."}]);
        return;
    }
    //https://pro-dev.cloudx.io/sdk  https://provisioning.cloudx.io/sdk
    [[NSUserDefaults standardUserDefaults] setObject:@"https://pro-dev.cloudx.io/sdk" forKey:kCLXCoreCloudXInitURLKey];
    NSDictionary *loopInfo = @{@"loop-index": @"0"};
    [[NSUserDefaults standardUserDefaults] setObject:loopInfo forKey:kCLXCoreUserKeyValueKey];
    
    // ⚠️⚠️⚠️ DEBUG-ONLY TEST MODE CONFIGURATION ⚠️⚠️⚠️
    // Test mode configuration - can be overridden via UserDefaults
#ifdef DEBUG
    // Check if test mode is already configured via UserDefaults
    BOOL testModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"CLXTestModeEnabled"];
    BOOL metaTestModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"CLXMetaTestModeEnabled"];
    
    NSLog(@"🔧 [BaseAdViewController] Current test mode settings:");
    NSLog(@"🔧 [BaseAdViewController] CLXTestModeEnabled: %@", testModeEnabled ? @"YES" : @"NO");
    NSLog(@"🔧 [BaseAdViewController] CLXMetaTestModeEnabled: %@", metaTestModeEnabled ? @"YES" : @"NO");
    
    if (testModeEnabled) {
        NSLog(@"🧪 [BaseAdViewController] *** TEST MODE ENABLED - USING HARDCODED TEST IFA ***");
    } else {
        NSLog(@"📱 [BaseAdViewController] *** TEST MODE DISABLED - USING REAL DEVICE IDFA ***");
    }
#else
    NSLog(@"🔒 [BaseAdViewController] Production build - test mode disabled");
#endif

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *testUserID = @"test-user-123";
        [self updateStatusUIWithState:AdStateLoading];
        NSLog(@"[BaseAdViewController] Calling CloudXCore initSDKWithAppKey:hashedUserID:completion:");
        [[CloudXCore shared] initSDKWithAppKey:appKey hashedUserID:testUserID completion:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    NSLog(@"✅ SDK Initialized: YES");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
                } else {
                    NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
                    NSLog(@"❌ SDK Init Failed: %@", errorMessage);
                }
                if (completion) completion(success, error);
            });
        }];
    });
}

- (void)initializeSDK {
    NSLog(@"[BaseAdViewController] initializeSDK called");
    [self initializeSDKWithCompletion:^(BOOL success, NSError * _Nullable error) {
        // No action needed for this convenience method
    }];
}

- (void)updateStatusUIWithState:(AdState)state {
    NSLog(@"[BaseAdViewController] updateStatusUIWithState: %ld", (long)state);
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
        
        NSLog(@"[StatusUI] Updating status label: %@ (color: %@)", text, color);
        self.statusLabel.text = text;
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
}

- (void)setupStatusUI {
    NSLog(@"[BaseAdViewController] setupStatusUI");
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
    NSLog(@"[BaseAdViewController] setupCenteredButtonWithTitle: %@", title);
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


@end 
