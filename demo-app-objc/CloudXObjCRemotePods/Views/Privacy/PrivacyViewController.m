//
//  PrivacyViewController.m
//  CloudXObjCRemotePods
//
//  Created by CloudX on 2025-09-06.
//

#import "PrivacyViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CoreLocation/CoreLocation.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import "DemoAppLogger.h"

@interface PrivacyViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

// Main UI Components
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *mainStackView;

// Test Scenario Section
@property (nonatomic, strong) UIView *scenarioSection;
@property (nonatomic, strong) UILabel *scenarioTitleLabel;
@property (nonatomic, strong) UIPickerView *scenarioPicker;
@property (nonatomic, strong) UILabel *currentScenarioLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *statusIndicator;

// Quick Setup Section
@property (nonatomic, strong) UIView *quickSetupSection;
@property (nonatomic, strong) UIButton *applyScenarioButton;
@property (nonatomic, strong) UIButton *simulateUSCAButton;
@property (nonatomic, strong) UIButton *simulateNonUSButton;
@property (nonatomic, strong) UIButton *resetAllButton;

// Manual Controls Section
@property (nonatomic, strong) UIView *manualControlsSection;
@property (nonatomic, strong) UITextField *gppStringField;
@property (nonatomic, strong) UITextField *gppSidField;
@property (nonatomic, strong) UISwitch *coppaSwitch;
@property (nonatomic, strong) UISwitch *attDeniedSwitch;
@property (nonatomic, strong) UISegmentedControl *locationSegmentedControl;
@property (nonatomic, strong) UIButton *applyManualButton;

// Bid Request Inspector Section
@property (nonatomic, strong) UIView *inspectorSection;
@property (nonatomic, strong) UIButton *generateBidRequestButton;
@property (nonatomic, strong) UILabel *keyFieldsLabel;
@property (nonatomic, strong) UIButton *viewJSONButton;
@property (nonatomic, strong) UIButton *clipboardButton;

// Data
@property (nonatomic, assign) GPPTestScenario currentScenario;
@property (nonatomic, strong) NSArray<NSString *> *scenarioTitles;
@property (nonatomic, strong) NSDictionary *lastBidRequestJSON;

@end

@implementation PrivacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"GPP Test Suite";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupData];
    [self setupScrollView];
    [self setupScenarioSection];
    [self setupQuickSetupSection];
    [self setupManualControlsSection];
    [self setupInspectorSection];
    [self updateUI];
}

- (void)setupData {
    self.currentScenario = GPPTestScenarioGPPAbsent;
    self.scenarioTitles = @[
        @"ATT Denied / LAT On",
        @"GPP Absent (Baseline)",
        @"GPP CCPA (Consent)",
        @"GPP CCPA (Opt-out)",
        @"GPP Non-US User",
        @"GPP US Non-California",
        @"COPPA Flagged App",
        @"Custom GPP String",
        @"Geo Info Test",
        @"Device Fields Test",
        @"Publisher API Test"
    ];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
    
    self.mainStackView = [[UIStackView alloc] init];
    self.mainStackView.axis = UILayoutConstraintAxisVertical;
    self.mainStackView.spacing = 24;
    self.mainStackView.alignment = UIStackViewAlignmentFill;
    self.mainStackView.distribution = UIStackViewDistributionEqualSpacing;
    self.mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.mainStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        
        [self.mainStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:16],
        [self.mainStackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [self.mainStackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [self.mainStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-40],
        [self.mainStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32]
    ]];
}

- (void)setupScenarioSection {
    self.scenarioSection = [self createSectionWithTitle:@"🧪 GPP Test Scenarios"];
    
    // Scenario picker
    self.scenarioPicker = [[UIPickerView alloc] init];
    self.scenarioPicker.delegate = self;
    self.scenarioPicker.dataSource = self;
    self.scenarioPicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scenarioSection addSubview:self.scenarioPicker];
    
    // Current scenario label
    self.currentScenarioLabel = [[UILabel alloc] init];
    self.currentScenarioLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.currentScenarioLabel.textColor = [UIColor labelColor];
    self.currentScenarioLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scenarioSection addSubview:self.currentScenarioLabel];
    
    // Status indicator and label
    UIStackView *statusStack = [[UIStackView alloc] init];
    statusStack.axis = UILayoutConstraintAxisHorizontal;
    statusStack.spacing = 8;
    statusStack.alignment = UIStackViewAlignmentCenter;
    statusStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.statusIndicator = [[UIView alloc] init];
    self.statusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusIndicator.layer.cornerRadius = 6;
    self.statusIndicator.backgroundColor = [UIColor systemGrayColor];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.statusLabel.textColor = [UIColor systemGrayColor];
    self.statusLabel.text = @"Ready to Test";
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [statusStack addArrangedSubview:self.statusIndicator];
    [statusStack addArrangedSubview:self.statusLabel];
    [self.scenarioSection addSubview:statusStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scenarioPicker.topAnchor constraintEqualToAnchor:self.scenarioSection.topAnchor constant:50],
        [self.scenarioPicker.leadingAnchor constraintEqualToAnchor:self.scenarioSection.leadingAnchor constant:12],
        [self.scenarioPicker.trailingAnchor constraintEqualToAnchor:self.scenarioSection.trailingAnchor constant:-12],
        [self.scenarioPicker.heightAnchor constraintEqualToConstant:100],
        
        [self.currentScenarioLabel.topAnchor constraintEqualToAnchor:self.scenarioPicker.bottomAnchor constant:10],
        [self.currentScenarioLabel.leadingAnchor constraintEqualToAnchor:self.scenarioSection.leadingAnchor constant:15],
        [self.currentScenarioLabel.trailingAnchor constraintEqualToAnchor:self.scenarioSection.trailingAnchor constant:-15],
        
        [statusStack.topAnchor constraintEqualToAnchor:self.currentScenarioLabel.bottomAnchor constant:8],
        [statusStack.leadingAnchor constraintEqualToAnchor:self.scenarioSection.leadingAnchor constant:15],
        [statusStack.bottomAnchor constraintEqualToAnchor:self.scenarioSection.bottomAnchor constant:-15],
        
        [self.statusIndicator.widthAnchor constraintEqualToConstant:12],
        [self.statusIndicator.heightAnchor constraintEqualToConstant:12]
    ]];
    
    [self.mainStackView addArrangedSubview:self.scenarioSection];
}

- (void)setupQuickSetupSection {
    self.quickSetupSection = [self createSectionWithTitle:@"⚙️ Quick Setup"];
    
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 10;
    buttonStack.alignment = UIStackViewAlignmentFill;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.applyScenarioButton = [self createButtonWithTitle:@"Apply Selected Scenario" 
                                     backgroundColor:[UIColor systemBlueColor] 
                                                    action:@selector(applySelectedScenario)];
    
    self.resetAllButton = [self createButtonWithTitle:@"Reset All Privacy Data" 
                                       backgroundColor:[UIColor systemRedColor] 
                                                action:@selector(resetAllPrivacyData)];
    
    [buttonStack addArrangedSubview:self.applyScenarioButton];
    [buttonStack addArrangedSubview:self.resetAllButton];
    
    [self.quickSetupSection addSubview:buttonStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.topAnchor constraintEqualToAnchor:self.quickSetupSection.topAnchor constant:45],
        [buttonStack.leadingAnchor constraintEqualToAnchor:self.quickSetupSection.leadingAnchor constant:16],
        [buttonStack.trailingAnchor constraintEqualToAnchor:self.quickSetupSection.trailingAnchor constant:-16],
        [buttonStack.bottomAnchor constraintEqualToAnchor:self.quickSetupSection.bottomAnchor constant:-16]
    ]];
    
    [self.mainStackView addArrangedSubview:self.quickSetupSection];
}

- (void)setupManualControlsSection {
    self.manualControlsSection = [self createSectionWithTitle:@"🔧 Manual Controls"];
    
    UIStackView *controlsStack = [[UIStackView alloc] init];
    controlsStack.axis = UILayoutConstraintAxisVertical;
    controlsStack.spacing = 12;
    controlsStack.alignment = UIStackViewAlignmentFill;
    controlsStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    // GPP String input
    UILabel *gppStringLabel = [self createLabelWithText:@"GPP String:"];
    self.gppStringField = [self createTextFieldWithPlaceholder:@"Enter GPP string (optional)"];
    
    // GPP SID input
    UILabel *gppSidLabel = [self createLabelWithText:@"GPP SID:"];
    self.gppSidField = [self createTextFieldWithPlaceholder:@"Enter SID (e.g., 7_8)"];
    
    // COPPA switch
    UISwitch *coppaSwitch = nil;
    UIStackView *coppaStack = [self createSwitchRowWithLabel:@"COPPA Enabled" switch:&coppaSwitch];
    self.coppaSwitch = coppaSwitch;
    
    // Apply Manual Controls button
    UIButton *applyManualButton = [self createButtonWithTitle:@"Apply Manual Controls" 
                                    backgroundColor:[UIColor systemPurpleColor]
                                                       action:@selector(applyManualControls)];
    
    [controlsStack addArrangedSubview:gppStringLabel];
    [controlsStack addArrangedSubview:self.gppStringField];
    [controlsStack addArrangedSubview:gppSidLabel];
    [controlsStack addArrangedSubview:self.gppSidField];
    [controlsStack addArrangedSubview:coppaStack];
    [controlsStack addArrangedSubview:applyManualButton];
    
    [self.manualControlsSection addSubview:controlsStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [controlsStack.topAnchor constraintEqualToAnchor:self.manualControlsSection.topAnchor constant:45],
        [controlsStack.leadingAnchor constraintEqualToAnchor:self.manualControlsSection.leadingAnchor constant:16],
        [controlsStack.trailingAnchor constraintEqualToAnchor:self.manualControlsSection.trailingAnchor constant:-16],
        [controlsStack.bottomAnchor constraintEqualToAnchor:self.manualControlsSection.bottomAnchor constant:-16]
    ]];
    
    [self.mainStackView addArrangedSubview:self.manualControlsSection];
}

- (void)setupInspectorSection {
    self.inspectorSection = [self createSectionWithTitle:@"🔍 Bid Request Inspector"];
    
    UIStackView *inspectorStack = [[UIStackView alloc] init];
    inspectorStack.axis = UILayoutConstraintAxisVertical;
    inspectorStack.spacing = 15;
    inspectorStack.alignment = UIStackViewAlignmentFill;
    inspectorStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.generateBidRequestButton = [self createButtonWithTitle:@"Generate Test Bid Request" 
                                                backgroundColor:[UIColor systemGreenColor] 
                                                         action:@selector(generateTestBidRequest)];
    
    self.keyFieldsLabel = [[UILabel alloc] init];
    self.keyFieldsLabel.font = [UIFont systemFontOfSize:14];
    self.keyFieldsLabel.textColor = [UIColor secondaryLabelColor];
    self.keyFieldsLabel.numberOfLines = 0;
    self.keyFieldsLabel.text = @"Generate a bid request to see key privacy fields...";
    self.keyFieldsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [inspectorStack addArrangedSubview:self.generateBidRequestButton];
    [inspectorStack addArrangedSubview:self.keyFieldsLabel];
    
    [self.inspectorSection addSubview:inspectorStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [inspectorStack.topAnchor constraintEqualToAnchor:self.inspectorSection.topAnchor constant:45],
        [inspectorStack.leadingAnchor constraintEqualToAnchor:self.inspectorSection.leadingAnchor constant:16],
        [inspectorStack.trailingAnchor constraintEqualToAnchor:self.inspectorSection.trailingAnchor constant:-16],
        [inspectorStack.bottomAnchor constraintEqualToAnchor:self.inspectorSection.bottomAnchor constant:-16]
    ]];
    
    [self.mainStackView addArrangedSubview:self.inspectorSection];
}

#pragma mark - Helper Methods

- (UIView *)createSectionWithTitle:(NSString *)title {
    UIView *section = [[UIView alloc] init];
    section.backgroundColor = [UIColor secondarySystemBackgroundColor];
    section.layer.cornerRadius = 12;
    section.layer.borderWidth = 1;
    section.layer.borderColor = [UIColor separatorColor].CGColor;
    section.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [section addSubview:titleLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:section.topAnchor constant:15],
        [titleLabel.leadingAnchor constraintEqualToAnchor:section.leadingAnchor constant:15],
        [titleLabel.trailingAnchor constraintEqualToAnchor:section.trailingAnchor constant:-15]
    ]];
    
    return section;
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
        [button.heightAnchor constraintEqualToConstant:40]
    ]];
    
    return button;
}

- (UILabel *)createLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    label.textColor = [UIColor labelColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (UITextField *)createTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [[UITextField alloc] init];
    textField.placeholder = placeholder;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont systemFontOfSize:14];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [textField.heightAnchor constraintEqualToConstant:36]
    ]];
    
    return textField;
}

- (UIStackView *)createSwitchRowWithLabel:(NSString *)labelText switch:(UISwitch **)switchPtr {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.distribution = UIStackViewDistributionFill;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *label = [self createLabelWithText:labelText];
    UISwitch *switchControl = [[UISwitch alloc] init];
    switchControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    [stack addArrangedSubview:label];
    [stack addArrangedSubview:switchControl];
    
    *switchPtr = switchControl;
    return stack;
}

#pragma mark - UIPickerView DataSource & Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.scenarioTitles.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.scenarioTitles[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentScenario = (GPPTestScenario)row;
    [self updateUI];
}

#pragma mark - Actions

- (void)applySelectedScenario {
    [self updateStatusWithMessage:@"Applying scenario..." color:[UIColor systemYellowColor]];
    
    @try {
        [self resetAllPrivacyDataSilently];
        
        switch (self.currentScenario) {
            case GPPTestScenarioATTDenied:
                [self setupATTDeniedScenario];
                break;
            case GPPTestScenarioGPPAbsent:
                [self setupGPPAbsentScenario];
                break;
            case GPPTestScenarioGPPCCPAConsent:
                [self setupGPPCCPAConsentScenario];
                break;
            case GPPTestScenarioGPPCCPAOptOut:
                [self setupGPPCCPAOptOutScenario];
                break;
            case GPPTestScenarioGPPNonUS:
                [self setupGPPNonUSScenario];
                break;
            case GPPTestScenarioGPPUSNonCalifornia:
                [self setupGPPUSNonCaliforniaScenario];
                break;
            case GPPTestScenarioCOPPAFlagged:
                [self setupCOPPAFlaggedScenario];
                break;
            case GPPTestScenarioCustomGPP:
                [self setupCustomGPPScenario];
                break;
            case GPPTestScenarioGeoInfo:
                [self setupGeoInfoScenario];
                break;
            case GPPTestScenarioDeviceFields:
                [self setupDeviceFieldsScenario];
                break;
            case GPPTestScenarioPublisherAPI:
                [self setupPublisherAPIScenario];
                break;
            default:
                [self setupGPPAbsentScenario];
                break;
        }
        
        [self updateStatusWithMessage:@"Scenario applied successfully" color:[UIColor systemGreenColor]];
        [self showAlertWithTitle:@"Scenario Applied" 
                         message:[NSString stringWithFormat:@"Successfully applied: %@", self.scenarioTitles[self.currentScenario]]];
        
    } @catch (NSException *exception) {
        [self updateStatusWithMessage:@"Scenario application failed" color:[UIColor systemRedColor]];
        [self showAlertWithTitle:@"Error" 
                         message:[NSString stringWithFormat:@"Failed to apply scenario: %@", exception.reason]];
    }
}

- (void)resetAllPrivacyData {
    [self updateStatusWithMessage:@"Resetting all data..." color:[UIColor systemYellowColor]];
    
    @try {
        [self resetAllPrivacyDataSilently];
        
        // Clear the bid request inspector display
        self.keyFieldsLabel.text = @"Generate a bid request to see key privacy fields...";
        
        [self updateStatusWithMessage:@"All data reset" color:[UIColor systemGreenColor]];
        [self showAlertWithTitle:@"Reset Complete" message:@"All privacy data has been cleared"];
    } @catch (NSException *exception) {
        [self updateStatusWithMessage:@"Reset failed" color:[UIColor systemRedColor]];
        [self showAlertWithTitle:@"Error" message:[NSString stringWithFormat:@"Reset failed: %@", exception.reason]];
    }
}

- (void)applyManualControls {
    [self updateStatusWithMessage:@"Applying manual controls..." color:[UIColor systemYellowColor]];
    
    @try {
        // Apply GPP String if provided
        NSString *gppString = self.gppStringField.text;
        if (gppString.length > 0) {
            [CloudXCore setGPPString:gppString];
        }
        
        // Apply GPP SID if provided
        NSString *gppSidText = self.gppSidField.text;
        if (gppSidText.length > 0) {
            // Parse comma-separated SID values (e.g., "7,8" or "8")
            NSArray<NSString *> *sidStrings = [gppSidText componentsSeparatedByString:@","];
            NSMutableArray<NSNumber *> *sidNumbers = [NSMutableArray array];
            for (NSString *sidString in sidStrings) {
                NSString *trimmed = [sidString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSInteger sidValue = [trimmed integerValue];
                if (sidValue > 0) {
                    [sidNumbers addObject:@(sidValue)];
                }
            }
            if (sidNumbers.count > 0) {
                [CloudXCore setGPPSid:sidNumbers];
            }
        }
        
        // Apply COPPA setting
        [CloudXCore setIsAgeRestrictedUser:self.coppaSwitch.isOn];
        
        [self updateStatusWithMessage:@"Manual controls applied" color:[UIColor systemGreenColor]];
        [self showAlertWithTitle:@"Applied" message:@"Manual privacy controls have been applied"];
        
    } @catch (NSException *exception) {
        [self updateStatusWithMessage:@"Manual controls failed" color:[UIColor systemRedColor]];
        [self showAlertWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to apply manual controls: %@", exception.reason]];
    }
}

- (void)generateTestBidRequest {
    [self updateStatusWithMessage:@"Generating bid request..." color:[UIColor systemYellowColor]];
    
    @try {
        // Determine test location based on privacy settings
        // For COPPA testing, we need to pass a location to see if privacy logic clears it
        CLLocation *testLocation = nil;
        
        // For COPPA testing, we always pass a test location to see if privacy logic clears it
        testLocation = [[CLLocation alloc] initWithLatitude:37.7749 longitude:-122.4194];
        
        // Create a test bid request using CLXBiddingConfigRequest
        CLXBiddingConfigRequest *bidRequest = [[CLXBiddingConfigRequest alloc] 
            initWithAdType:CLXAdTypeBanner
                 adUnitID:@"test-gpp-ad-unit"
        storedImpressionId:@"test-impression-id"
                    dealID:@""
                 bidFloor:@1.0
            displayManager:@"CloudX-iOS-Demo"
        displayManagerVer:@"1.0.0"
               publisherID:@"test-publisher"
                  location:testLocation
                 userAgent:@"CloudX-Demo-App/1.0"
               adapterInfo:@{}
       nativeAdRequirements:nil
       skadRequestParameters:@{}
                      tmax:@3.0
                  impModel:nil
                  settings:[CLXSettings sharedInstance]];
        
        // Debug: Log bid request generation
        [[DemoAppLogger sharedInstance] logMessage:@"🔍 [DEBUG] Generated test bid request for privacy testing"];
        
        // Extract key privacy fields for display
        NSMutableString *keyFields = [[NSMutableString alloc] init];
        
        // Check IFA
        NSString *ifa = bidRequest.device.ifa;
        BOOL ifaCleared = !ifa || [ifa isEqualToString:@"00000000-0000-0000-0000-000000000000"] || ifa.length == 0;
        [keyFields appendFormat:@"• IFA: %@\n", ifaCleared ? @"Cleared" : @"Present"];
        
        // Check Geo
        NSNumber *lat = bidRequest.device.geo.lat;
        NSNumber *lon = bidRequest.device.geo.lon;
        BOOL geoCleared = !lat || !lon || ([lat doubleValue] == 0.0 && [lon doubleValue] == 0.0);
        if (geoCleared) {
            [keyFields appendString:@"• Geo: Cleared\n"];
        } else {
            [keyFields appendFormat:@"• Geo: %@,%@\n", lat, lon];
        }
        
        // Check GPP
        NSString *gpp = bidRequest.regulations.ext.gpp;
        [keyFields appendFormat:@"• GPP: %@\n", gpp ? @"Present" : @"Absent"];
        
        // Check GPP SID
        NSArray *gppSid = bidRequest.regulations.ext.gppSid;
        [keyFields appendFormat:@"• GPP SID: %@\n", gppSid ? [gppSid componentsJoinedByString:@","] : @"Absent"];
        
        // Check COPPA
        NSNumber *coppa = bidRequest.regulations.coppa;
        [keyFields appendFormat:@"• COPPA: %@\n", coppa ? coppa.stringValue : @"Absent"];
        
        // Check CCPA
        NSString *ccpa = bidRequest.regulations.ext.iab.usPrivacyString;
        [keyFields appendFormat:@"• CCPA: %@\n", ccpa ?: @"Absent"];
        
        self.keyFieldsLabel.text = keyFields;
        
        [self updateStatusWithMessage:@"Bid request generated" color:[UIColor systemGreenColor]];
        
    } @catch (NSException *exception) {
        [self updateStatusWithMessage:@"Bid request generation failed" color:[UIColor systemRedColor]];
        [self showAlertWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to generate bid request: %@", exception.reason]];
    }
}

#pragma mark - Test Scenario Implementations

- (void)setupATTDeniedScenario {
    // TEST SIMULATION: Simulate ATT denied for testing purposes
    // NOTE: Real publishers would never do this - this is test-only code
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SimulateATTDenied"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupGPPAbsentScenario {
    // GPP data already cleared by resetAllPrivacyDataSilently
    // This is the baseline scenario
}

- (void)setupGPPCCPAConsentScenario {
    // Set GPP string with CCPA consent (sale opt-out = 0, sharing opt-out = 0)
    NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@8]];
    // TEST SIMULATION: Mock California geo headers for testing
    [self setMockGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"usa",
        @"cloudfront-viewer-country-region": @"ca"
    }];
}

- (void)setupGPPCCPAOptOutScenario {
    // Set GPP string with CCPA opt-out (sale opt-out = 1, sharing opt-out = 1)
    NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YYN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@8]];
    // TEST SIMULATION: Mock California geo headers for testing
    [self setMockGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"usa",
        @"cloudfront-viewer-country-region": @"ca"
    }];
}

- (void)setupGPPNonUSScenario {
    // Set GPP string for non-US testing
    NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YYN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@8]];
    // TEST SIMULATION: Mock non-US geo headers for testing
    [self setMockGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"deu",
        @"cloudfront-viewer-country-region": @"by"
    }];
}

- (void)setupGPPUSNonCaliforniaScenario {
    // Set GPP string with US-National section (SID=7)
    NSString *gppString = @"DBACNYA~BVWqWBg.YA~1YYN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@7]];
    // TEST SIMULATION: Mock US non-California geo headers for testing
    [self setMockGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"usa",
        @"cloudfront-viewer-country-region": @"ny"
    }];
}

- (void)setupCOPPAFlaggedScenario {
    // Enable COPPA (should override other privacy settings)
    [CloudXCore setIsAgeRestrictedUser:YES];
    
    // Also set some GPP data to test COPPA override
    NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@8]];
}

- (void)setupCustomGPPScenario {
    // Demonstrate custom GPP string entry via manual controls
    // This scenario shows how publishers can set custom GPP values
    // Use the manual controls section to enter custom GPP string and SID
}

- (void)setupGeoInfoScenario {
    // Test geo-targeting with GPP
    NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@8]];
    // TEST SIMULATION: Mock detailed geo headers for testing
    [self setMockGeoHeaders:@{
        @"cloudfront-viewer-country-iso3": @"usa",
        @"cloudfront-viewer-country-region": @"ca",
        @"cloudfront-viewer-city": @"San Francisco",
        @"cloudfront-viewer-postal-code": @"94102"
    }];
}

- (void)setupDeviceFieldsScenario {
    // Test device field population with privacy considerations
    NSString *gppString = @"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN";
    [CloudXCore setGPPString:gppString];
    [CloudXCore setGPPSid:@[@8]];
    // Device fields (model, OS, version, type) should be populated when allowed
}

- (void)setupPublisherAPIScenario {
    // Demonstrate publisher API usage patterns
    [CloudXCore setGPPString:@"DBACNYA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA~1YNN"];
    [CloudXCore setGPPSid:@[@8]];
    [CloudXCore setIsUserConsent:YES];
    [CloudXCore setIsDoNotSell:NO];
    // This shows typical publisher integration using only public APIs
}

#pragma mark - Helper Methods

- (void)resetAllPrivacyDataSilently {
    // Clear all CloudXCore privacy settings using public APIs
    [CloudXCore setCCPAPrivacyString:nil];
    [CloudXCore setGPPString:nil];
    [CloudXCore setGPPSid:nil];
    [CloudXCore setIsAgeRestrictedUser:NO];
    [CloudXCore setIsUserConsent:YES]; // Reset to default consent state
    [CloudXCore setIsDoNotSell:NO]; // Reset to default
    
    // Clear test simulation flags
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SimulateATTDenied"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCLXCoreGeoHeadersKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setMockGeoHeaders:(NSDictionary *)headers {
    // TEST SIMULATION: Store mock CloudFront geo headers for testing
    // NOTE: Real publishers would never do this - this is test-only code
    [[NSUserDefaults standardUserDefaults] setObject:headers forKey:kCLXCoreGeoHeadersKey]; 
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)updateUI {
    self.currentScenarioLabel.text = [NSString stringWithFormat:@"Current: %@", self.scenarioTitles[self.currentScenario]];
    
    // Update picker selection
    [self.scenarioPicker selectRow:self.currentScenario inComponent:0 animated:NO];
}

- (void)updateStatusWithMessage:(NSString *)message color:(UIColor *)color {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = message ?: @"Unknown Status";
        self.statusLabel.textColor = color;
        self.statusIndicator.backgroundColor = color;
    });
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
    [self updateUI];
}

@end