//
//  GPPScenarioPickerView.m
//  CloudXObjCRemotePods
//
//  Created by refactoring for SOLID principles.
//
//  IMPLEMENTATION NOTES:
//  ---------------------
//  This file contains the complete implementation of the GPP scenario picker
//  component. It encapsulates all privacy test logic to keep parent view
//  controllers clean and maintainable.
//
//  ARCHITECTURE:
//  -------------
//  - Self-contained UIView subclass
//  - Creates its own UI elements (label, button)
//  - Manages internal state (current scenario)
//  - Handles user interaction (button tap, action sheet)
//  - Integrates with CloudXCore SDK (privacy settings)
//
//  KEY METHODS:
//  ------------
//  - setupUI: Creates label + button, configures layout
//  - presentScenarioPickerFromViewController: Shows action sheet with scenarios
//  - selectScenario:withTitle: Updates state and applies scenario
//  - applyScenario: Calls CloudXCore SDK APIs for selected scenario
//  - resetGPPSettings: Clears all privacy settings to baseline
//
//  PRIVACY SCENARIOS IMPLEMENTED:
//  -------------------------------
//  Each scenario represents a specific privacy compliance test case:
//
//  1. None (GPPTestScenarioNone)
//     - No privacy settings applied
//     - Baseline for comparison
//
//  2. GPP Absent (GPPTestScenarioGPPAbsent)
//     - No GPP string set
//     - Tests behavior when GPP data unavailable
//
//  3. CCPA Consent (GPPTestScenarioGPPCCPAConsent)
//     - GPP: "DBABLA~BVVqAAEABBENA.QA" (consent)
//     - GPP SID: [8] (US-California)
//     - Expected: Full geo data (lat/lon) present
//
//  4. CCPA Opt-Out (GPPTestScenarioGPPCCPAOptOut)
//     - GPP: "DBABLA~BVVqAAEABBENA.YA" (opt-out)
//     - GPP SID: [8] (US-California)
//     - Expected: Lat/lon removed, context preserved
//
//  5. Non-US/EU (GPPTestScenarioGPPNonUS)
//     - GPP: European consent string
//     - GPP SID: [8] (EU framework)
//     - Expected: GDPR privacy rules apply
//
//  6. US Non-California (GPPTestScenarioGPPUSNonCalifornia)
//     - GPP: "DBACNYA~BVWqWBg.YA~1YYN"
//     - GPP SID: [7] (US-National, not CA-specific)
//     - Expected: CCPA doesn't apply outside California
//
//  7. ATT Denied (GPPTestScenarioATTDenied)
//     - Requires iOS Settings: Tracking disabled
//     - Expected: Personal data removed by iOS system
//
//  IAB USERDEFAULTS INTEGRATION:
//  -----------------------------
//  The component writes directly to IAB standard UserDefaults keys:
//
//  - IABGPP_HDR_GppString - IAB GPP consent string (CloudX reads this internally)
//  - IABGPP_GppSID - IAB GPP Section ID string (CloudX reads this internally)
//  - [CloudXCore setIsUserConsent:] - Sets user consent flag (CloudX API)
//  - [CloudXCore setIsDoNotSell:] - Sets CCPA do-not-sell flag (CloudX API)
//
//  NOTE: GPP methods (setGPPString/setGPPSid) were removed from CloudX public API
//  to align with Android's approach. Both platforms now read GPP from IAB standard
//  storage. Publishers should use IAB CMP SDKs; this demo component writes directly
//  to IAB keys for testing purposes only.
//
//  TESTING WORKFLOW:
//  -----------------
//  1. User taps button → buttonTapped called
//  2. Component finds parent VC → findViewController
//  3. Component presents action sheet → presentScenarioPickerFromViewController:
//  4. User selects scenario → selectScenario:withTitle: called
//  5. Component updates UI → updateButtonTitle:
//  6. Component applies settings → applyScenario:
//  7. CloudXCore SDK updated with privacy settings
//  8. Console logs show selected scenario
//
//  MAINTENANCE:
//  ------------
//  To add a new scenario:
//  1. Add enum case in GPPTestScenario typedef
//  2. Add action in presentScenarioPickerFromViewController:
//  3. Add switch case in applyScenario:
//  4. Update header documentation
//
//  SOLID PRINCIPLES DEMONSTRATED:
//  -------------------------------
//  ✅ Single Responsibility: Only manages GPP scenarios
//  ✅ Open/Closed: Extend scenarios without modifying clients
//  ✅ Liskov Substitution: UIView contract preserved
//  ✅ Interface Segregation: Minimal public API
//  ✅ Dependency Inversion: Depends on UIKit/CloudXCore abstractions

#import "GPPScenarioPickerView.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

/**
 * @typedef GPPTestScenario
 * @brief Enumeration of available privacy test scenarios
 *
 * @discussion
 * Each enum value represents a specific privacy compliance test case.
 * The enum order matches the presentation order in the action sheet.
 */
typedef NS_ENUM(NSInteger, GPPTestScenario) {
    GPPTestScenarioNone = 0,                    // No privacy settings
    GPPTestScenarioGPPAbsent,                   // No GPP string
    GPPTestScenarioGPPCCPAConsent,              // CCPA consent (.QA)
    GPPTestScenarioGPPCCPAOptOut,               // CCPA opt-out (.YA)
    GPPTestScenarioGPPNonUS,                    // EU/Germany (GDPR via GPP)
    GPPTestScenarioGPPUSNonCalifornia,          // US non-CA (Oregon, NY, etc)
    GPPTestScenarioATTDenied,                   // ATT tracking disabled
    // GDPR/TCF Scenarios
    GPPTestScenarioGDPRFullConsent,             // EU TCF: All purposes + vendor consent
    GPPTestScenarioGDPRDenied,                  // EU TCF: No purposes consented
    GPPTestScenarioGDPRPurpose1Denied,          // EU TCF: Purpose 1 (device access) denied
    GPPTestScenarioGDPRVendorDenied             // EU TCF: Purposes OK but vendor denied
};

@interface GPPScenarioPickerView ()
@property (nonatomic, strong) UILabel *scenarioLabel;
@property (nonatomic, strong) UIButton *scenarioButton;
@property (nonatomic, assign) GPPTestScenario currentScenario;
@end

@implementation GPPScenarioPickerView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI Setup

- (void)setupUI {
    self.currentScenario = GPPTestScenarioNone;
    
    // Create vertical stack
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 8;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stackView];
    
    // Label
    self.scenarioLabel = [[UILabel alloc] init];
    self.scenarioLabel.text = @"GPP Test Scenario:";
    self.scenarioLabel.font = [UIFont boldSystemFontOfSize:14];
    self.scenarioLabel.textColor = [UIColor labelColor];
    [stackView addArrangedSubview:self.scenarioLabel];
    
    // Button
    self.scenarioButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.scenarioButton setTitle:@"None (Tap to Change)" forState:UIControlStateNormal];
    [self.scenarioButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.scenarioButton.backgroundColor = [UIColor systemBlueColor];
    [self.scenarioButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.scenarioButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.scenarioButton.layer.cornerRadius = 8;
    self.scenarioButton.contentEdgeInsets = UIEdgeInsetsMake(12, 16, 12, 16);
    self.scenarioButton.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:self.scenarioButton];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scenarioButton.widthAnchor constraintEqualToConstant:320]
    ]];
}

#pragma mark - User Interaction

- (void)buttonTapped {
    UIViewController *viewController = [self findViewController];
    if (viewController) {
        [self presentScenarioPickerFromViewController:viewController];
    }
}

- (void)presentScenarioPickerFromViewController:(UIViewController *)viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select GPP Test Scenario"
                                                                   message:@"Choose a privacy scenario to test"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Add scenario actions
    [self addScenarioAction:alert scenario:GPPTestScenarioNone title:@"None" subtitle:@"No privacy settings"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGPPAbsent title:@"GPP Absent" subtitle:@"No GPP string"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGPPCCPAConsent title:@"CCPA Consent (.QA)" subtitle:@"User gave consent"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGPPCCPAOptOut title:@"CCPA Opt-Out (.YA)" subtitle:@"User opted out"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGPPNonUS title:@"Non-US (Germany)" subtitle:@"Outside US jurisdiction"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGPPUSNonCalifornia title:@"US Non-California (NY)" subtitle:@"US but not CA"];
    [self addScenarioAction:alert scenario:GPPTestScenarioATTDenied title:@"⭐️ ATT Denied" subtitle:@"Tracking disabled in iOS Settings"];
    
    // GDPR/TCF Scenarios
    [self addScenarioAction:alert scenario:GPPTestScenarioGDPRFullConsent title:@"🇪🇺 GDPR Full Consent" subtitle:@"All purposes + vendor OK"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGDPRDenied title:@"🇪🇺 GDPR Denied" subtitle:@"No purposes consented"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGDPRPurpose1Denied title:@"🇪🇺 GDPR Purpose 1 Denied" subtitle:@"Device access denied"];
    [self addScenarioAction:alert scenario:GPPTestScenarioGDPRVendorDenied title:@"🇪🇺 GDPR Vendor Denied" subtitle:@"Purposes OK, vendor NO"];
    
    // Cancel action
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    // Present
    [viewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Scenario Management

- (void)addScenarioAction:(UIAlertController *)alert 
                 scenario:(GPPTestScenario)scenario 
                    title:(NSString *)title 
                 subtitle:(NSString *)subtitle {
    NSString *fullTitle = [NSString stringWithFormat:@"%@\n%@", title, subtitle];
    UIAlertAction *action = [UIAlertAction actionWithTitle:fullTitle
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
        [self selectScenario:scenario withTitle:title];
    }];
    
    if (self.currentScenario == scenario) {
        [action setValue:@YES forKey:@"checked"];
    }
    
    [alert addAction:action];
}

- (void)selectScenario:(GPPTestScenario)scenario withTitle:(NSString *)title {
    self.currentScenario = scenario;
    [self updateButtonTitle:title];
    [self applyScenario:scenario];
}

- (void)updateButtonTitle:(NSString *)scenarioName {
    NSString *buttonTitle = [NSString stringWithFormat:@"%@ (Tap to Change)", scenarioName];
    [self.scenarioButton setTitle:buttonTitle forState:UIControlStateNormal];
}

- (NSArray<NSNumber *> *)dynamicGPPSid {
    // Dynamically determine SID based on actual CloudFront geo location
    CLXGeoLocationService *geoService = [CLXGeoLocationService shared];
    BOOL isCalifornia = [geoService isCaliforniaUser];
    BOOL isUS = [geoService isUSUser];
    
    if (isCalifornia) {
        [[DemoAppLogger sharedInstance] logMessage:@"📍 Detected California → Using SID 8 (US-CA)"];
        return @[@8];  // US-California
    } else if (isUS) {
        [[DemoAppLogger sharedInstance] logMessage:@"📍 Detected US (non-CA) → Using SID 7 (US-National)"];
        return @[@7];  // US-National
    } else {
        [[DemoAppLogger sharedInstance] logMessage:@"📍 Detected Non-US → Using empty SID array"];
        return @[];    // Non-US regions
    }
}

- (void)applyScenario:(GPPTestScenario)scenario {
    [self resetGPPSettings];
    
    switch (scenario) {
        case GPPTestScenarioNone:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: None (real geo data from CloudFront API)"];
            break;
            
        case GPPTestScenarioGPPAbsent:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: GPP Absent (real geo data from CloudFront API)"];
            break;
            
        case GPPTestScenarioGPPCCPAConsent:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: CCPA Consent (Allow All) - AUTO-DETECTING LOCATION"];
            [self setIABGPPString:@"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA"];
            [self setIABGPPSid:[self dynamicGPPSid]];  // Dynamic based on real location
            break;
            
        case GPPTestScenarioGPPCCPAOptOut:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: CCPA Opt-Out (Disallow All) - AUTO-DETECTING LOCATION"];
            [self setIABGPPString:@"DBABrw~BAAVAAAAAABA.QA~BAUAAABA.QA"];
            [self setIABGPPSid:[self dynamicGPPSid]];  // Dynamic based on real location
            // IAB US Privacy: 1YYN = Version 1, Notice given, OPTED OUT, Not LSPA
            [CloudXCore setCCPAPrivacyString:@"1YYN"];
            break;
            
        case GPPTestScenarioGPPNonUS:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: Non-US (Allow All) - AUTO-DETECTING LOCATION"];
            [self setIABGPPString:@"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA"];
            [self setIABGPPSid:[self dynamicGPPSid]];  // Dynamic based on real location
            break;
            
        case GPPTestScenarioGPPUSNonCalifornia:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: US Non-California - AUTO-DETECTING LOCATION"];
            [self setIABGPPString:@"DBABrw~BAAAAAAAAABA.QA~BAAAAABA.QA"];
            [self setIABGPPSid:[self dynamicGPPSid]];  // Dynamic based on real location
            break;
            
        case GPPTestScenarioATTDenied:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GPP Scenario: ATT Denied (real geo data from CloudFront API)"];
            [[DemoAppLogger sharedInstance] logMessage:@"⚠️ To test: Go to iOS Settings → Privacy & Security → Tracking → Disable for this app"];
            [[DemoAppLogger sharedInstance] logMessage:@"⚠️ Then restart the app and select this scenario"];
            break;
            
        // GDPR/TCF Scenarios - Set IAB TCF UserDefaults keys
        case GPPTestScenarioGDPRFullConsent:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GDPR Scenario: Full Consent (All purposes + vendor)"];
            [self setIABTCFGdprApplies:YES];
            // TCF string with all purposes enabled and vendor 1510 (CloudX) consented
            // This is a real TCF 2.2 string from Google UMP with full consent
            [self setIABTCFString:@"CQbFSYAQbFSYAEsACBENCFFoAP_gAEPgACiQINJB7C7FbSFCyLZzaLsAMAhHRsAAQoQAAASBAmABQAKQIAQCgkAYFASABAACAAAAICRBIQIECAAAAUAAAAAAAAAEAAAAAAAIIAAAgAEAAAAIAAAKAIAAEAAIAAAAEAAAmAgAAIIACAAAgAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAQNVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAAA"];
            [self setIABTCFPurposeConsents:@"1111111111"];  // All 10 purposes granted
            break;
            
        case GPPTestScenarioGDPRDenied:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GDPR Scenario: Denied (No purposes consented)"];
            [self setIABTCFGdprApplies:YES];
            // TCF string with no purposes enabled
            [self setIABTCFString:@"CQbFSYAQbFSYAEsACBENCFFgAAAAAEPgACiQAAANVSD2F2K2kKFkWCmwXYAYBCujYAAhQgAAAkCBMACgAUgQAgFJIAgCIEAAAAAAAAAQEiCQAAQEBAAAIACAAAAAAAIAAAAAAAQQAABAAIAAAAAAAAUAQAAIAAQAAAAIAABEhAAAQQAEAAAAAAAQAA"];
            [self setIABTCFPurposeConsents:@"0000000000"];  // All purposes denied
            break;
            
        case GPPTestScenarioGDPRPurpose1Denied:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GDPR Scenario: Purpose 1 Denied (Device access denied)"];
            [self setIABTCFGdprApplies:YES];
            // TCF string with purpose 1 disabled, others enabled
            [self setIABTCFString:@"CQbFSYAQbFSYAEsACDENCFFgAHAAAEPgACiQACBA1VIPYXYraQoWRYKbBdgBgEK6NgACFCAAACQIEwAKABSBACAUkgCAIgQAAAAAAAABASIJAABAQEAAAgAIAAAAAAAgAAAAAABBAAAEAAgAAAAAAABQBAAAgABAAAAAgAAESEAABBAAQAAAAAABAAA"];
            [self setIABTCFPurposeConsents:@"0111111111"];  // Purpose 1 denied, others granted
            break;
            
        case GPPTestScenarioGDPRVendorDenied:
            [[DemoAppLogger sharedInstance] logMessage:@"🧪 GDPR Scenario: Vendor Denied (Purposes OK, CloudX vendor denied)"];
            [self setIABTCFGdprApplies:YES];
            // TCF string with all purposes but vendor consent section excludes CloudX (1510)
            [self setIABTCFString:@"CQbFSYAQbFSYAEsACDENCFFgAPAAAEPgACiQAFIBA1VIPYXYraQoWRYKbBdgBgEK6NgACFCAAACQIEwAKABSBACAUkgCAIgQAAAAAAAABASIJAABAQEAAAgAIAAAAAAAgAAAAAABBAAAEAAgAAAAAAABQBAAAgABAAAAAgAAESEAABBAAQAAAAAABAAA"];
            [self setIABTCFPurposeConsents:@"1111111111"];  // All purposes granted
            // Note: Vendor consent is encoded in the TCF string itself - the above string excludes CloudX vendor ID
            break;
    }
}

#pragma mark - IAB TCF UserDefaults Methods

- (void)setIABTCFGdprApplies:(BOOL)applies {
    [[NSUserDefaults standardUserDefaults] setInteger:(applies ? 1 : 0) forKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIABTCFString:(nullable NSString *)tcString {
    if (tcString) {
        [[NSUserDefaults standardUserDefaults] setObject:tcString forKey:@"IABTCF_TCString"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_TCString"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIABTCFPurposeConsents:(nullable NSString *)purposeConsents {
    if (purposeConsents) {
        [[NSUserDefaults standardUserDefaults] setObject:purposeConsents forKey:@"IABTCF_PurposeConsents"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_PurposeConsents"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIABGPPString:(nullable NSString *)gppString {
    if (gppString) {
        [[NSUserDefaults standardUserDefaults] setObject:gppString forKey:@"IABGPP_HDR_GppString"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABGPP_HDR_GppString"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIABGPPSid:(nullable NSArray<NSNumber *> *)gppSid {
    if (gppSid && gppSid.count > 0) {
        // Convert array to underscore-delimited string (IAB standard format)
        NSMutableArray<NSString *> *sidStrings = [NSMutableArray array];
        for (NSNumber *sid in gppSid) {
            [sidStrings addObject:[sid stringValue]];
        }
        NSString *sidString = [sidStrings componentsJoinedByString:@"_"];
        [[NSUserDefaults standardUserDefaults] setObject:sidString forKey:@"IABGPP_GppSID"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABGPP_GppSID"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetGPPSettings {
    // Clear IAB GPP UserDefaults directly (CloudX reads from these)
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABGPP_HDR_GppString"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABGPP_GppSID"];
    
    // Clear IAB TCF UserDefaults (GDPR)
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_PurposeConsents"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_VendorConsents"];
    
    // Clear IAB US Privacy (CCPA)
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABUSPrivacy_String"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Clear CloudX privacy settings (public APIs that still exist)
    [CloudXCore setIsUserConsent:YES];
    [CloudXCore setIsDoNotSell:NO];
}

#pragma mark - Helper

- (UIViewController *)findViewController {
    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

@end

