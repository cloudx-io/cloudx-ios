//
//  PrivacyViewController.m
//  CloudXObjCRemotePods
//
//  Created by CloudX on 2025-09-06.
//

#import "PrivacyViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CoreLocation/CoreLocation.h>

@interface PrivacyViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *buttonStackView;
@property (nonatomic, strong) UIView *statusIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIStackView *statusStack;

// Individual privacy buttons
@property (nonatomic, strong) UIButton *setGDPRButton;
@property (nonatomic, strong) UIButton *setCCPAButton;
@property (nonatomic, strong) UIButton *setCOPPAButton;
@property (nonatomic, strong) UIButton *setGPPButton;
@property (nonatomic, strong) UIButton *clearAllButton;
@end

@implementation PrivacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"[PrivacyViewController] viewDidLoad");
    self.title = @"Privacy Settings";
    
    [self setupScrollView];
    [self setupPrivacyButtons];
    [self setupStatusUI];
    [self updateStatusUI];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    
    self.buttonStackView = [[UIStackView alloc] init];
    self.buttonStackView.axis = UILayoutConstraintAxisVertical;
    self.buttonStackView.spacing = 15;
    self.buttonStackView.alignment = UIStackViewAlignmentFill;
    self.buttonStackView.distribution = UIStackViewDistributionEqualSpacing;
    self.buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.buttonStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.buttonStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:20],
        [self.buttonStackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:20],
        [self.buttonStackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-20],
        [self.buttonStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-20],
        [self.buttonStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-40]
    ]];
}

- (void)setupPrivacyButtons {
    NSLog(@"[PrivacyViewController] setupPrivacyButtons");
    
    // GDPR Only Button
    self.setGDPRButton = [self createButtonWithTitle:@"Set GDPR Only" 
                                     backgroundColor:[UIColor systemBlueColor] 
                                              action:@selector(setGDPROnly)];
    
    // CCPA Only Button  
    self.setCCPAButton = [self createButtonWithTitle:@"Set CCPA Only"
                                     backgroundColor:[UIColor systemOrangeColor]
                                              action:@selector(setCCPAOnly)];
    
    // COPPA Only Button
    self.setCOPPAButton = [self createButtonWithTitle:@"Set COPPA Only"
                                      backgroundColor:[UIColor systemTealColor]
                                               action:@selector(setCOPPAOnly)];
    
    // Full GPP Button
    self.setGPPButton = [self createButtonWithTitle:@"Set Full GPP (All Privacy)"
                                    backgroundColor:[UIColor systemPurpleColor]
                                             action:@selector(setFullGPP)];
    
    // Clear All Button
    self.clearAllButton = [self createButtonWithTitle:@"Clear All Privacy Data"
                                       backgroundColor:[UIColor systemRedColor]
                                                action:@selector(clearAllPrivacyData)];
    
    // Add buttons to stack view
    [self.buttonStackView addArrangedSubview:self.setGDPRButton];
    [self.buttonStackView addArrangedSubview:self.setCCPAButton];
    [self.buttonStackView addArrangedSubview:self.setCOPPAButton];
    [self.buttonStackView addArrangedSubview:self.setGPPButton];
    [self.buttonStackView addArrangedSubview:self.clearAllButton];
}

- (UIButton *)createButtonWithTitle:(NSString *)title 
                    backgroundColor:(UIColor *)backgroundColor 
                             action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *config = [UIButtonConfiguration filledButtonConfiguration];
        config.title = title;
        config.baseBackgroundColor = backgroundColor;
        config.baseForegroundColor = [UIColor whiteColor];
        config.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        config.contentInsets = NSDirectionalEdgeInsetsMake(12, 20, 12, 20);
        button.configuration = config;
    } else {
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = backgroundColor;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        button.layer.cornerRadius = 8;
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        button.contentEdgeInsets = UIEdgeInsetsMake(12, 20, 12, 20);
        #pragma clang diagnostic pop
    }
    
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    [NSLayoutConstraint activateConstraints:@[
        [button.heightAnchor constraintEqualToConstant:50]
    ]];
    
    return button;
}

- (void)setupStatusUI {
    NSLog(@"[PrivacyViewController] setupStatusUI");
    
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
    self.statusIndicator.backgroundColor = [UIColor systemGrayColor];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"No Privacy Data Set";
    self.statusLabel.textColor = [UIColor systemGrayColor];
    
    [self.statusStack addArrangedSubview:self.statusIndicator];
    [self.statusStack addArrangedSubview:self.statusLabel];
    
    // Add status to button stack (at the top)
    [self.buttonStackView insertArrangedSubview:self.statusStack atIndex:0];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.statusIndicator.widthAnchor constraintEqualToConstant:12],
        [self.statusIndicator.heightAnchor constraintEqualToConstant:12]
    ]];
}

#pragma mark - Privacy Actions

- (void)setGDPROnly {
    [self showUnsupportedPrivacyAlert:@"GDPR" 
                              message:@"GDPR privacy compliance is not yet supported by our auction server. Including GDPR data in bid requests will cause 502 errors. This feature will be available in a future release."];
}

- (void)setCCPAOnly {
    NSLog(@"[PrivacyViewController] setCCPAOnly called");
    [self updateStatusWithMessage:@"Setting CCPA..." color:[UIColor systemYellowColor]];
    
    @try {
        [self clearAllPrivacyDataSilently];
        
        // Use CloudXCore public API instead of UserDefaults
        NSString *ccpaPrivacyString = @"1YNN"; // CCPA opt-out string
        [CloudXCore setCCPAPrivacyString:ccpaPrivacyString];
        
        NSLog(@"✅ [PrivacyViewController] CCPA Only set successfully");
        NSLog(@"   CCPA Privacy: %@", ccpaPrivacyString);
        
        [self updateStatusWithMessage:@"CCPA Only Set" color:[UIColor systemOrangeColor]];
        [self showAlertWithTitle:@"CCPA Set" message:@"Only CCPA privacy data has been set.\n\nTest if bid requests work with CCPA only."];
        
    } @catch (NSException *exception) {
        NSLog(@"❌ [PrivacyViewController] Exception setting CCPA: %@", exception);
        [self updateStatusWithMessage:@"CCPA Error" color:[UIColor systemRedColor]];
        [self showAlertWithTitle:@"CCPA Error" message:[NSString stringWithFormat:@"Failed to set CCPA: %@", exception.reason]];
    }
}

- (void)setCOPPAOnly {
    [self showUnsupportedPrivacyAlert:@"COPPA" 
                              message:@"COPPA (Children's Online Privacy Protection Act) is not yet supported by our auction server. Including COPPA data in bid requests will cause 502 errors. This feature will be available in a future release."];
}

- (void)setFullGPP {
    [self showUnsupportedPrivacyAlert:@"Full GPP" 
                              message:@"Full GPP (Global Privacy Platform) is not yet supported by our auction server. GPP includes GDPR and COPPA data which cause 502 errors. Only CCPA is currently supported. This feature will be available in a future release."];
}

- (void)clearAllPrivacyData {
    NSLog(@"[PrivacyViewController] clearAllPrivacyData called");
    [self updateStatusWithMessage:@"Clearing All..." color:[UIColor systemYellowColor]];
    
    @try {
        [self clearAllPrivacyDataSilently];
        
        NSLog(@"✅ [PrivacyViewController] All privacy data cleared successfully");
        
        [self updateStatusWithMessage:@"All Privacy Cleared" color:[UIColor systemGreenColor]];
        [self showAlertWithTitle:@"Privacy Cleared" message:@"All privacy data has been cleared.\n\nBid requests will not include any privacy regulations."];
        
    } @catch (NSException *exception) {
        NSLog(@"❌ [PrivacyViewController] Exception clearing privacy data: %@", exception);
        [self updateStatusWithMessage:@"Clear Error" color:[UIColor systemRedColor]];
        [self showAlertWithTitle:@"Clear Error" message:[NSString stringWithFormat:@"Failed to clear privacy data: %@", exception.reason]];
    }
}

- (void)clearAllPrivacyDataSilently {
    // Use CloudXCore public API to clear privacy data instead of direct UserDefaults access
    [CloudXCore setCCPAPrivacyString:nil];
    
    // Clear GPP string and section IDs using UserDefaults (these don't have CloudXCore APIs yet)
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"IABGPP_HDR_GppString"];
    [userDefaults removeObjectForKey:@"IABGPP_GppSID"];
    
    // Clear hashed identifiers from privacy service
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    [privacyService setHashedUserId:nil];
    [privacyService setHashedGeoIp:nil];
    
    [userDefaults synchronize];
}

#pragma mark - UI Updates

- (void)updateStatusUI {
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // TODO: uncomment when we add server side support for COPPA and GDPR
//    BOOL hasGDPR = [privacyService gdprConsentString] != nil;
    BOOL hasCCPA = [privacyService ccpaPrivacyString] != nil;
//    BOOL hasCOPPA = [privacyService coppaApplies] != nil;
    BOOL hasGPP = [userDefaults stringForKey:@"IABGPP_HDR_GppString"] != nil;
    
    // TODO: uncomment when we add server side support for COPPA and GDPR
//    if (hasGPP) {
//        [self updateStatusWithMessage:@"Full GPP Set" color:[UIColor systemPurpleColor]];
//    } else if (hasGDPR && hasCCPA && hasCOPPA) {
//        [self updateStatusWithMessage:@"All Privacy Set" color:[UIColor systemPurpleColor]];
//    } else if (hasGDPR && hasCCPA) {
//        [self updateStatusWithMessage:@"GDPR + CCPA Set" color:[UIColor systemIndigoColor]];
//    } else if (hasGDPR && hasCOPPA) {
//        [self updateStatusWithMessage:@"GDPR + COPPA Set" color:[UIColor systemIndigoColor]];
//    } else if (hasCCPA && hasCOPPA) {
//        [self updateStatusWithMessage:@"CCPA + COPPA Set" color:[UIColor systemIndigoColor]];
//    } else if (hasGDPR) {
//        [self updateStatusWithMessage:@"GDPR Only Set" color:[UIColor systemBlueColor]];
//    } else if (hasCCPA) {
//        [self updateStatusWithMessage:@"CCPA Only Set" color:[UIColor systemOrangeColor]];
//    } else if (hasCOPPA) {
//        [self updateStatusWithMessage:@"COPPA Only Set" color:[UIColor systemTealColor]];
//    } else {
//        [self updateStatusWithMessage:@"No Privacy Data Set" color:[UIColor systemGrayColor]];
//    }
    
    if (hasCCPA) {
        [self updateStatusWithMessage:@"CCPA Only Set" color:[UIColor systemOrangeColor]];
    } else {
        [self updateStatusWithMessage:@"No Privacy Data Set" color:[UIColor systemGrayColor]];
    }
}

- (void)updateStatusWithMessage:(NSString *)message color:(UIColor *)color {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = message ?: @"Unknown Status";
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
}

- (void)showUnsupportedPrivacyAlert:(NSString *)privacyType message:(NSString *)message {
    NSString *title = [NSString stringWithFormat:@"%@ Not Supported", privacyType];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    // Update status to show unsupported
    [self updateStatusWithMessage:[NSString stringWithFormat:@"%@ Not Supported", privacyType] 
                            color:[UIColor systemRedColor]];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateStatusUI];
}

@end
