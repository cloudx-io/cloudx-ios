//
//  SettingsViewController.m
//  CloudXObjCRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

#import "SettingsViewController.h"
#import "UserDefaultsSettings.h"
#import <CloudXCore/CloudXCore.h>

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
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.settings = [UserDefaultsSettings sharedSettings];
    self.title = @"Settings";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4; // SDK, Ad Units, Privacy, Logging
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2; // SDK Settings
        case 1: return 4; // Ad Unit Settings (Banner, MREC, Interstitial, Rewarded)
        case 2: return 3; // Privacy: Consent, US Privacy, User Targeting
        case 3: return 4; // Logging: Enable, Emojis, Timestamps, Level
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"SDK Settings";
        case 1: return @"Ad Unit Settings";
        case 2: return @"Privacy";
        case 3: return @"Logging Controls 🪵";
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return @"V=Verbose (all logs), D=Debug (dev logs), I=Info (key events), W=Warn (issues), E=Error (failures only). Toggle emojis to test plain text mode for log aggregation systems.";
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
            if (indexPath.row == 0) {
                cell.textLabel.text = @"App Key";
                textField.text = self.settings.appKey;
            } else {
                cell.textLabel.text = @"Init URL";
                textField.text = self.settings.SDKinitURL;
            }
            break;
        case 1: // Ad Units
            switch (indexPath.row) {
                case 0: cell.textLabel.text = @"Banner"; textField.text = self.settings.bannerAdUnitId; break;
                case 1: cell.textLabel.text = @"MREC"; textField.text = self.settings.mrecAdUnitId; break;
                case 2: cell.textLabel.text = @"Interstitial"; textField.text = self.settings.interstitialAdUnitId; break;
                case 3: cell.textLabel.text = @"Rewarded"; textField.text = self.settings.rewardedAdUnitId; break;
            }
            break;
        case 2: // Privacy
            switch (indexPath.row) {
                case 0: cell.textLabel.text = @"Consent String"; textField.text = self.settings.consentString; break;
                case 1: cell.textLabel.text = @"US Privacy String"; textField.text = self.settings.usPrivacyString; break;
                case 2: {
                    cell.textLabel.text = @"User Targeting";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    toggle.on = self.settings.userTargeting;
                    [toggle addTarget:self action:@selector(userTargetingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    [textField removeFromSuperview];
                    break;
                }
            }
            break;
        case 3: // Logging
            [textField removeFromSuperview]; // We'll use switches for all logging controls
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Logging Enabled";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    // Read from UserDefaults, default is YES (enabled)
                    toggle.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"LoggingDisabled"];
                    toggle.tag = 300;
                    [toggle addTarget:self action:@selector(loggingToggleChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    break;
                }
                case 1: {
                    cell.textLabel.text = @"Emojis Enabled";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    // Default is YES, store override in UserDefaults
                    toggle.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"LoggingEmojisDisabled"];
                    toggle.tag = 301;
                    [toggle addTarget:self action:@selector(loggingToggleChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = toggle;
                    break;
                }
                case 2: {
                    cell.textLabel.text = @"Timestamps Enabled";
                    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
                    // Default is NO, store override in UserDefaults
                    toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"LoggingTimestampsEnabled"];
                    toggle.tag = 302;
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
    }
    return cell;
}

- (void)userTargetingSwitchChanged:(UISwitch *)sender {
    self.settings.userTargeting = sender.isOn;
}

- (void)loggingToggleChanged:(UISwitch *)sender {
    if (sender.tag == 300) {
        // Logging Enabled/Disabled - use setMinLogLevel: with CLXLogLevelNone to disable
        if (sender.isOn) {
            // Re-enable with previously saved level, defaulting to Info
            NSInteger savedLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"LoggingLevel"];
            [CloudXCore setMinLogLevel:(savedLevel > 0 ? savedLevel : CLXLogLevelInfo)];
        } else {
            // Disable all logging
            [CloudXCore setMinLogLevel:CLXLogLevelNone];
        }
        [[NSUserDefaults standardUserDefaults] setBool:!sender.isOn forKey:@"LoggingDisabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (sender.tag == 301) {
        // Emojis Enabled/Disabled
        [CloudXCore setLoggingEmojisEnabled:sender.isOn];
        [[NSUserDefaults standardUserDefaults] setBool:!sender.isOn forKey:@"LoggingEmojisDisabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (sender.tag == 302) {
        // Timestamps Enabled/Disabled
        [CloudXCore setLoggingTimestampsEnabled:sender.isOn];
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"LoggingTimestampsEnabled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)logLevelChanged:(UISegmentedControl *)sender {
    // 0=Verbose, 1=Debug, 2=Info, 3=Warn, 4=Error
    [CloudXCore setMinLogLevel:sender.selectedSegmentIndex];
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:@"LoggingLevel"];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSInteger tag = textField.tag;
    if (tag == 0) self.settings.appKey = textField.text;
    else if (tag == 1) self.settings.SDKinitURL = textField.text;
    else if (tag == 10) self.settings.bannerAdUnitId = textField.text;
    else if (tag == 11) self.settings.mrecAdUnitId = textField.text;
    else if (tag == 12) self.settings.interstitialAdUnitId = textField.text;
    else if (tag == 13) self.settings.rewardedAdUnitId = textField.text;
    else if (tag == 20) self.settings.consentString = textField.text;
    else if (tag == 21) self.settings.usPrivacyString = textField.text;
}

@end

