//
//  SettingsViewController.m
//  CloudXObjCRemotePods
//
//  Created by Xenoss on 15.09.2025.
//

#import "SettingsViewController.h"
#import "UserDefaultsSettings.h"

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
    return 3; // SDK, Placement, Privacy
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2; // SDK Settings
        case 1: return 6; // Placement Settings
        case 2: return 3; // Privacy
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"SDK Settings";
        case 1: return @"Placement Settings";
        case 2: return @"Privacy";
        default: return nil;
    }
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
        case 1: // Placement
            switch (indexPath.row) {
                case 0: cell.textLabel.text = @"Banner"; textField.text = self.settings.bannerPlacement; break;
                case 1: cell.textLabel.text = @"MREC"; textField.text = self.settings.mrecPlacement; break;
                case 2: cell.textLabel.text = @"Interstitial"; textField.text = self.settings.interstitialPlacement; break;
                case 3: cell.textLabel.text = @"Rewarded"; textField.text = self.settings.rewardedPlacement; break;
                case 4: cell.textLabel.text = @"Native Small"; textField.text = self.settings.nativeSmallPlacement; break;
                case 5: cell.textLabel.text = @"Native Medium"; textField.text = self.settings.nativeMediumPlacement; break;
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
    }
    return cell;
}

- (void)userTargetingSwitchChanged:(UISwitch *)sender {
    self.settings.userTargeting = sender.isOn;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSInteger tag = textField.tag;
    if (tag == 0) self.settings.appKey = textField.text;
    else if (tag == 1) self.settings.SDKinitURL = textField.text;
    else if (tag == 10) self.settings.bannerPlacement = textField.text;
    else if (tag == 11) self.settings.mrecPlacement = textField.text;
    else if (tag == 12) self.settings.interstitialPlacement = textField.text;
    else if (tag == 13) self.settings.rewardedPlacement = textField.text;
    else if (tag == 14) self.settings.nativeSmallPlacement = textField.text;
    else if (tag == 15) self.settings.nativeMediumPlacement = textField.text;
    else if (tag == 20) self.settings.consentString = textField.text;
    else if (tag == 21) self.settings.usPrivacyString = textField.text;
}

@end

