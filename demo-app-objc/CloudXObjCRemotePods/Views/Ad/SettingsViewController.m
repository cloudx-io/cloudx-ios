//
//  SettingsViewController.m
//  CloudXObjCRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

#import "SettingsViewController.h"
#import "UserDefaultsSettings.h"
#import <CloudXCore/CloudXCore.h>
#import "CLXBidResponseSwizzler.h"

@interface CLXTextField : UITextField
@end

@implementation CLXTextField

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copy:) ||
            action == @selector(paste:) ||
            action == @selector(cut:)) {
            return YES; // explicitly allow
        }
        return [super canPerformAction:action withSender:sender];
}

- (void)copy:(id)sender {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = self.text;
}

- (void)paste:(id)sender {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    self.text = pb.string;
}

- (void)cut:(id)sender {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = self.text;
    self.text = @"";
}

@end


@interface SettingsViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UserDefaultsSettings *settings;
@property (nonatomic, weak) UITextField *hashedUserIdTextField;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.settings = [UserDefaultsSettings sharedSettings];
    self.title = @"Settings";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4; // SDK, Ad Unit, Logging, QA Tools
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 3; // SDK Settings: App Key, Init URL, Hashed User ID
        case 1: return 4; // Ad Unit Settings
        case 2: return 4; // Logging: Enable, Emojis, Timestamps, Level
        case 3: return 2; // QA Tools: Print Bid Response, Simulate Error
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"SDK Settings";
        case 1: return @"Ad Unit Settings";
        case 2: return @"Logging Controls 🪵";
        case 3: return @"🔍 QA Tools";
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return @"V=Verbose (all logs), D=Debug (dev logs), I=Info (key events), W=Warn (issues), E=Error (failures only). Toggle emojis to test plain text mode for log aggregation systems.";
    }
    if (section == 3) {
        return @"Print Bid Response logs the full JSON to Xcode console. Simulate Error arms a one-shot error that fires on the next ad load, then resets to Off.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    UITextField *textField = [[CLXTextField alloc] initWithFrame:CGRectMake(150, 7, cell.contentView.bounds.size.width - 160, 30)];
    textField.delegate = self;
    textField.tag = indexPath.section * 10 + indexPath.row;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [cell.contentView addSubview:textField];

    switch (indexPath.section) {
        case 0: // SDK
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"App Key";
                    textField.text = self.settings.appKey;
                    break;
                case 1:
                    cell.textLabel.text = @"Init URL";
                    textField.text = self.settings.SDKinitURL;
                    break;
                case 2: {
                    cell.textLabel.text = @"Hashed User ID";
                    textField.text = self.settings.hashedUserId;
                    
                    // Store reference to this text field
                    self.hashedUserIdTextField = textField;
                    
                    // Add a small "Apply" button to the right of the text field
                    UIButton *applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
                    [applyButton setTitle:@"Apply" forState:UIControlStateNormal];
                    applyButton.frame = CGRectMake(0, 0, 55, 30);
                    [applyButton addTarget:self action:@selector(applyHashedUserId:) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = applyButton;
                    
                    // Adjust text field frame to make room for the button
                    textField.frame = CGRectMake(150, 7, cell.contentView.bounds.size.width - 220, 30);
                    break;
                }
            }
            break;
        case 1: // Ad Unit
            switch (indexPath.row) {
                case 0: cell.textLabel.text = @"Banner"; textField.text = self.settings.bannerAdUnitId; break;
                case 1: cell.textLabel.text = @"MREC"; textField.text = self.settings.mrecAdUnitId; break;
                case 2: cell.textLabel.text = @"Interstitial"; textField.text = self.settings.interstitialAdUnitId; break;
                case 3: cell.textLabel.text = @"Rewarded"; textField.text = self.settings.rewardedAdUnitId; break;
            }
            break;
        case 2: // Logging
            [textField removeFromSuperview]; // We'll use switches for all logging controls
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Logging Enabled";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    // Read from UserDefaults, default is YES (enabled)
                    toggle.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"LoggingDisabled"];
                    toggle.tag = 200;
                    [toggle addTarget:self action:@selector(loggingToggleChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Emojis Enabled";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    // Default is YES, store override in UserDefaults
                    toggle.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"LoggingEmojisDisabled"];
                    toggle.tag = 201;
                    [toggle addTarget:self action:@selector(loggingToggleChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"Timestamps Enabled";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    // Default is NO, store override in UserDefaults
                    toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"LoggingTimestampsEnabled"];
                    toggle.tag = 202;
                    [toggle addTarget:self action:@selector(loggingToggleChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    break;
                }
                case 3: {
                    cell.textLabel.text = @"Log Level";
                    UISegmentedControl *levelControl = [[UISegmentedControl alloc] initWithItems:@[@"V", @"D", @"I", @"W", @"E"]];
                    NSInteger currentLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"LoggingLevel"];
                    levelControl.selectedSegmentIndex = currentLevel > 0 ? currentLevel : 2; // Default to Info
                    levelControl.frame = CGRectMake(0, 0, 200, 30);
                    [levelControl addTarget:self action:@selector(logLevelChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = levelControl;
                    break;
                }
            }
            break;
        case 3: // QA Tools
            [textField removeFromSuperview];
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Print Full Bid Response";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    toggle.on = self.settings.printBidResponse;
                    toggle.tag = 300;
                    [toggle addTarget:self action:@selector(printBidResponseToggleChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Simulate Error";
                    UISegmentedControl *errorPicker = [[UISegmentedControl alloc] initWithItems:@[@"Off", @"400", @"500", @"NoFill"]];
                    errorPicker.selectedSegmentIndex = [CLXBidResponseSwizzler simulatedErrorType];
                    errorPicker.frame = CGRectMake(0, 0, 220, 30);
                    [errorPicker addTarget:self action:@selector(simulateErrorChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = errorPicker;
                    break;
                }
            }
            break;
    }
    return cell;
}

- (void)applyHashedUserId:(UIButton *)sender {
    // Get the current text from the stored text field reference
    NSString *hashedUserId = self.hashedUserIdTextField.text;
    
    // Save it to settings and apply to SDK (allow empty/nil to clear)
    self.settings.hashedUserId = hashedUserId;
    [[CloudXCore shared] setHashedUserID:hashedUserId];
    
    // Dismiss keyboard if it's showing
    [self.hashedUserIdTextField resignFirstResponder];
    
    // Show confirmation alert
    NSString *message;
    if (hashedUserId && hashedUserId.length > 0) {
        message = [NSString stringWithFormat:@"Hashed User ID updated to:\n%@", hashedUserId];
    } else {
        message = @"Hashed User ID cleared";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Applied"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)loggingToggleChanged:(UISwitch *)sender {
    if (sender.tag == 200) {
        // Logging Enabled/Disabled (using CLXLogLevelNone to disable)
        [CloudXCore setMinLogLevel:sender.isOn ? CLXLogLevelVerbose : CLXLogLevelNone];
        [[NSUserDefaults standardUserDefaults] setBool:!sender.isOn forKey:@"LoggingDisabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"🪵 Logging %@", sender.isOn ? @"ENABLED" : @"DISABLED");
    } else if (sender.tag == 201) {
        // Emojis Enabled/Disabled
        [CloudXCore setLoggingEmojisEnabled:sender.isOn];
        [[NSUserDefaults standardUserDefaults] setBool:!sender.isOn forKey:@"LoggingEmojisDisabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"🪵 Emojis %@", sender.isOn ? @"ENABLED" : @"DISABLED");
    } else if (sender.tag == 202) {
        // Timestamps Enabled/Disabled
        [CloudXCore setLoggingTimestampsEnabled:sender.isOn];
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"LoggingTimestampsEnabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"🪵 Timestamps %@", sender.isOn ? @"ENABLED" : @"DISABLED");
    }
}

- (void)logLevelChanged:(UISegmentedControl *)sender {
    // 0=Verbose, 1=Debug, 2=Info, 3=Warn, 4=Error
    [CloudXCore setMinLogLevel:sender.selectedSegmentIndex];
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:@"LoggingLevel"];
    NSArray *levelNames = @[@"VERBOSE", @"DEBUG", @"INFO", @"WARN", @"ERROR"];
    NSLog(@"🪵 Log level set to: %@", levelNames[sender.selectedSegmentIndex]);
}

#pragma mark - QA Tools

- (void)printBidResponseToggleChanged:(UISwitch *)sender {
    self.settings.printBidResponse = sender.isOn;
    
    // Enable swizzling when turned on
    if (sender.isOn) {
        [CLXBidResponseSwizzler enableSwizzling];
    }
    
    NSLog(@"🔍 Print Full Bid Response %@", sender.isOn ? @"ENABLED" : @"DISABLED");
}

- (void)simulateErrorChanged:(UISegmentedControl *)sender {
    CLXSimulatedErrorType errorType = (CLXSimulatedErrorType)sender.selectedSegmentIndex;
    [CLXBidResponseSwizzler setSimulatedErrorType:errorType];
    
    NSArray *labels = @[@"Off", @"HTTP 400", @"HTTP 500", @"No Fill"];
    NSLog(@"🔍 Simulate Error: %@", labels[sender.selectedSegmentIndex]);
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSInteger tag = textField.tag;
    if (tag == 0) self.settings.appKey = textField.text;
    else if (tag == 1) self.settings.SDKinitURL = textField.text;
    else if (tag == 2) self.settings.hashedUserId = textField.text;
    else if (tag == 10) self.settings.bannerAdUnitId = textField.text;
    else if (tag == 11) self.settings.mrecAdUnitId = textField.text;
    else if (tag == 12) self.settings.interstitialAdUnitId = textField.text;
    else if (tag == 13) self.settings.rewardedAdUnitId = textField.text;
}

@end

