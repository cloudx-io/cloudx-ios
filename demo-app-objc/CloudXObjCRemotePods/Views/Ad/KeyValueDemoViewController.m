//
//  KeyValueDemoViewController.m
//  CloudXObjCRemotePods
//
//  Created by CloudX on 2025-01-09.
//

#import "KeyValueDemoViewController.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXKeyValueState.h>
#import "DemoAppLogger.h"

@interface KeyValueDemoViewController () <UITableViewDelegate, UITableViewDataSource>

// UI Components
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *mainStackView;

// Add Key-Value Section
@property (nonatomic, strong) UIView *addKVSection;
@property (nonatomic, strong) UISegmentedControl *kvTypeSegment;
@property (nonatomic, strong) UITextField *keyTextField;
@property (nonatomic, strong) UITextField *valueTextField;
@property (nonatomic, strong) UIButton *addButton;

// Current Key-Values Section
@property (nonatomic, strong) UIView *currentKVSection;
@property (nonatomic, strong) UITableView *kvTableView;
@property (nonatomic, strong) UIButton *clearAllButton;

// Info Section
@property (nonatomic, strong) UIView *infoSection;
@property (nonatomic, strong) UILabel *infoLabel;

// Data
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *displayedUserKVs;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *displayedAppKVs;

@end

@implementation KeyValueDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Key-Value Pairs";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupData];
    [self setupScrollView];
    [self setupAddKVSection];
    [self setupCurrentKVSection];
    [self setupInfoSection];
    [self refreshDisplayedData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDisplayedData];
}

- (void)setupData {
    self.displayedUserKVs = [NSMutableDictionary dictionary];
    self.displayedAppKVs = [NSMutableDictionary dictionary];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    
    self.mainStackView = [[UIStackView alloc] init];
    self.mainStackView.axis = UILayoutConstraintAxisVertical;
    self.mainStackView.spacing = 20;
    self.mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.mainStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        
        [self.mainStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:20],
        [self.mainStackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:20],
        [self.mainStackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-20],
        [self.mainStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-20],
        [self.mainStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-40]
    ]];
}

- (void)setupAddKVSection {
    self.addKVSection = [self createSectionWithTitle:@"Add Key-Value Pair"];
    
    // Type selector
    self.kvTypeSegment = [[UISegmentedControl alloc] initWithItems:@[@"User-Level", @"App-Level"]];
    self.kvTypeSegment.selectedSegmentIndex = 0;
    
    // Key input
    UILabel *keyLabel = [[UILabel alloc] init];
    keyLabel.text = @"Key:";
    keyLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    
    self.keyTextField = [[UITextField alloc] init];
    self.keyTextField.placeholder = @"e.g., age, interest, app_version";
    self.keyTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.keyTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // Value input
    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = @"Value:";
    valueLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    
    self.valueTextField = [[UITextField alloc] init];
    self.valueTextField.placeholder = @"e.g., 25, gaming, 1.2.3";
    self.valueTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.valueTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // Add button
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addButton setTitle:@"Add Key-Value Pair" forState:UIControlStateNormal];
    self.addButton.backgroundColor = [UIColor systemBlueColor];
    [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addButton.layer.cornerRadius = 8;
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.addButton addTarget:self action:@selector(addKeyValuePair:) forControlEvents:UIControlEventTouchUpInside];
    
    // Stack in section
    UIStackView *contentStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.kvTypeSegment,
        keyLabel,
        self.keyTextField,
        valueLabel,
        self.valueTextField,
        self.addButton
    ]];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 12;
    contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addKVSection addSubview:contentStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [contentStack.topAnchor constraintEqualToAnchor:self.addKVSection.topAnchor constant:50],
        [contentStack.leadingAnchor constraintEqualToAnchor:self.addKVSection.leadingAnchor constant:16],
        [contentStack.trailingAnchor constraintEqualToAnchor:self.addKVSection.trailingAnchor constant:-16],
        [contentStack.bottomAnchor constraintEqualToAnchor:self.addKVSection.bottomAnchor constant:-16],
        [self.addButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    [self.mainStackView addArrangedSubview:self.addKVSection];
}

- (void)setupCurrentKVSection {
    self.currentKVSection = [self createSectionWithTitle:@"Current Key-Value Pairs"];
    
    // Table view
    self.kvTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.kvTableView.delegate = self;
    self.kvTableView.dataSource = self;
    self.kvTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.kvTableView.layer.cornerRadius = 8;
    self.kvTableView.layer.borderWidth = 1;
    self.kvTableView.layer.borderColor = [UIColor separatorColor].CGColor;
    [self.kvTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"KVCell"];
    
    // Clear all button
    self.clearAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearAllButton setTitle:@"Clear All Key-Value Pairs" forState:UIControlStateNormal];
    self.clearAllButton.backgroundColor = [UIColor systemRedColor];
    [self.clearAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.clearAllButton.layer.cornerRadius = 8;
    self.clearAllButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.clearAllButton addTarget:self action:@selector(clearAllKeyValues:) forControlEvents:UIControlEventTouchUpInside];
    
    UIStackView *contentStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.kvTableView,
        self.clearAllButton
    ]];
    contentStack.axis = UILayoutConstraintAxisVertical;
    contentStack.spacing = 12;
    contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.currentKVSection addSubview:contentStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [contentStack.topAnchor constraintEqualToAnchor:self.currentKVSection.topAnchor constant:50],
        [contentStack.leadingAnchor constraintEqualToAnchor:self.currentKVSection.leadingAnchor constant:16],
        [contentStack.trailingAnchor constraintEqualToAnchor:self.currentKVSection.trailingAnchor constant:-16],
        [contentStack.bottomAnchor constraintEqualToAnchor:self.currentKVSection.bottomAnchor constant:-16],
        [self.kvTableView.heightAnchor constraintEqualToConstant:200],
        [self.clearAllButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    [self.mainStackView addArrangedSubview:self.currentKVSection];
}

- (void)setupInfoSection {
    self.infoSection = [self createSectionWithTitle:@"Info"];
    
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.font = [UIFont systemFontOfSize:13];
    self.infoLabel.textColor = [UIColor secondaryLabelColor];
    self.infoLabel.text = @"📌 Key-value pairs are injected into bid requests at server-configured paths.\n\n"
                          @"👤 User-Level: User-specific targeting (e.g., age, interests)\n"
                          @"   • Respects privacy regulations (GDPR/CCPA)\n"
                          @"   • Cleared when privacy requires removing PII\n\n"
                          @"📱 App-Level: App-specific targeting (e.g., app version, build)\n"
                          @"   • Not affected by privacy regulations\n"
                          @"   • Always included in bid requests\n\n"
                          @"💡 The server controls where these values appear in the bid request via the keyValuePaths configuration.";
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.infoSection addSubview:self.infoLabel];
    
    // Add sample data button
    UIButton *sampleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [sampleButton setTitle:@"Load Sample Key-Values (for testing)" forState:UIControlStateNormal];
    sampleButton.backgroundColor = [UIColor systemGreenColor];
    [sampleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    sampleButton.layer.cornerRadius = 8;
    sampleButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [sampleButton addTarget:self action:@selector(loadSampleKeyValues:) forControlEvents:UIControlEventTouchUpInside];
    sampleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.infoSection addSubview:sampleButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.infoLabel.topAnchor constraintEqualToAnchor:self.infoSection.topAnchor constant:50],
        [self.infoLabel.leadingAnchor constraintEqualToAnchor:self.infoSection.leadingAnchor constant:16],
        [self.infoLabel.trailingAnchor constraintEqualToAnchor:self.infoSection.trailingAnchor constant:-16],
        
        [sampleButton.topAnchor constraintEqualToAnchor:self.infoLabel.bottomAnchor constant:16],
        [sampleButton.leadingAnchor constraintEqualToAnchor:self.infoSection.leadingAnchor constant:16],
        [sampleButton.trailingAnchor constraintEqualToAnchor:self.infoSection.trailingAnchor constant:-16],
        [sampleButton.heightAnchor constraintEqualToConstant:44],
        [sampleButton.bottomAnchor constraintEqualToAnchor:self.infoSection.bottomAnchor constant:-16]
    ]];
    
    [self.mainStackView addArrangedSubview:self.infoSection];
}

- (UIView *)createSectionWithTitle:(NSString *)title {
    UIView *section = [[UIView alloc] init];
    section.backgroundColor = [UIColor secondarySystemBackgroundColor];
    section.layer.cornerRadius = 12;
    section.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [section addSubview:titleLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:section.topAnchor constant:16],
        [titleLabel.leadingAnchor constraintEqualToAnchor:section.leadingAnchor constant:16]
    ]];
    
    return section;
}

#pragma mark - Actions

- (void)addKeyValuePair:(UIButton *)sender {
    NSString *key = [self.keyTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *value = [self.valueTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (key.length == 0 || value.length == 0) {
        [self showAlert:@"Error" message:@"Both key and value are required"];
        return;
    }
    
    BOOL isUserLevel = self.kvTypeSegment.selectedSegmentIndex == 0;
    
    if (isUserLevel) {
        [[CloudXCore shared] setUserKeyValue:key value:value];
        self.displayedUserKVs[key] = value;
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Added user key-value: %@ = %@", key, value]];
    } else {
        [[CloudXCore shared] setAppKeyValue:key value:value];
        self.displayedAppKVs[key] = value;
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Added app key-value: %@ = %@", key, value]];
    }
    
    // Clear inputs
    self.keyTextField.text = @"";
    self.valueTextField.text = @"";
    [self.keyTextField resignFirstResponder];
    [self.valueTextField resignFirstResponder];
    
    // Refresh table
    [self.kvTableView reloadData];
    
    [self showAlert:@"Success" message:[NSString stringWithFormat:@"Added %@ key-value pair: %@ = %@", 
                                        isUserLevel ? @"user-level" : @"app-level", key, value]];
}

- (void)clearAllKeyValues:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear All?" 
                                                                   message:@"This will remove all user and app-level key-value pairs." 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear All" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[CloudXCore shared] clearAllKeyValues];
        [self.displayedUserKVs removeAllObjects];
        [self.displayedAppKVs removeAllObjects];
        [self.kvTableView reloadData];
        [[DemoAppLogger sharedInstance] logMessage:@"🧹 Cleared all key-value pairs"];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)refreshDisplayedData {
    // Get current state from CLXKeyValueState
    CLXKeyValueState *state = [CLXKeyValueState shared];
    self.displayedUserKVs = [state.userKeyValues mutableCopy];
    self.displayedAppKVs = [state.appKeyValues mutableCopy];
    [self.kvTableView reloadData];
}

- (void)loadSampleKeyValues:(UIButton *)sender {
    [[DemoAppLogger sharedInstance] logMessage:@"🧪 Loading HIGH-ROI targeting key-values..."];
    
    // 💡 PRO TIP:
    // These key-values represent the "Golden List" of high-value signals that mobile ad bidders pay a premium for.
    // By passing these signals as First-Party Data, you help bidders identify high-quality users (e.g., payers,
    // frequent users, heavy ad watchers) without violating privacy rules.
    //
    // The values below create a "Whale" profile (high-spending, highly engaged user) to demonstrate
    // how to structure these signals for maximum CPM lift.
    
    // ============================================
    // 1. MONETIZATION & SPEND (The "Whale" Signals)
    // ============================================
    
    // #1 Signal. Immediate price floor increase for known spenders.
    [[CloudXCore shared] setUserKeyValue:@"payer_status" value:@"whale"];
    
    // Bidders prefer hard number buckets over abstract segments.
    [[CloudXCore shared] setUserKeyValue:@"iap_total_bucket" value:@"50-100"];
    
    // Recent payers are significantly more likely to convert again.
    [[CloudXCore shared] setUserKeyValue:@"recency_purchase" value:@"0-7d"];
    
    // Identifies high-quality recurring revenue users.
    [[CloudXCore shared] setUserKeyValue:@"subscription_status" value:@"active"];
    
    // Forward-looking predictive metric (gold for bidders).
    [[CloudXCore shared] setUserKeyValue:@"predicted_ltv" value:@"high"];
    
    // ============================================
    // 2. ENGAGEMENT & RETENTION
    // ============================================
    
    // Advertisers bid differently for new users vs. loyal veterans.
    [[CloudXCore shared] setUserKeyValue:@"user_tenure" value:@"d30"];
    
    // Critical for predicting ad fatigue and engagement quality.
    [[CloudXCore shared] setUserKeyValue:@"session_frequency" value:@"daily"];
    
    // Proof of deep engagement; correlates with viewability.
    [[CloudXCore shared] setUserKeyValue:@"level_achieved" value:@"42"];
    
    // Composite score (e.g., sessions/day + duration).
    [[CloudXCore shared] setUserKeyValue:@"engagement_score" value:@"high"];
    
    // Users on old versions often monetize poorly or have bugs.
    [[CloudXCore shared] setUserKeyValue:@"app_version_age" value:@"latest"];
    
    // Gamified progression status for VIP management.
    [[CloudXCore shared] setUserKeyValue:@"loyalty_tier" value:@"gold"];

    // ============================================
    // 3. AD CONSUMPTION HABITS
    // ============================================
    
    // User watches high volume (10+) of rewarded videos/day.
    [[CloudXCore shared] setUserKeyValue:@"ad_whale" value:@"true"];
    
    // Propensity to click/engage with rewarded video units.
    [[CloudXCore shared] setUserKeyValue:@"reward_affinity" value:@"high"];
    
    // Helps with frequency capping and inventory pricing logic.
    [[CloudXCore shared] setUserKeyValue:@"ads_today_bucket" value:@"6-15"];
    
    // User has history of installing apps from interstitial ads.
    [[CloudXCore shared] setUserKeyValue:@"interstitial_clicker" value:@"true"];
    
    // Impressions shown later in a session often perform differently.
    [[CloudXCore shared] setUserKeyValue:@"session_depth" value:@"5"];

    // ============================================
    // 4. USER CONTEXT & DEMOGRAPHICS (Privacy-Safe)
    // ============================================
    
    // Never use exact age. Brackets are standard and safe.
    [[CloudXCore shared] setUserKeyValue:@"age_bracket" value:@"25-34"];
    
    // Only if voluntarily provided by user.
    [[CloudXCore shared] setUserKeyValue:@"gender_declared" value:@"n/a"];
    
    // Contextual interests based on app usage patterns.
    [[CloudXCore shared] setUserKeyValue:@"interests" value:@"strategy,rpg,tech"];
    
    // Proxy for disposable income (e.g., iPhone 16 Pro vs iPhone 8).
    [[CloudXCore shared] setUserKeyValue:@"device_tier" value:@"high_end"];
    
    // Heavy video ads prefer Wifi/5G connections.
    [[CloudXCore shared] setUserKeyValue:@"connection_type" value:@"wifi"];
    
    // Critical for age-gated ad categories (alcohol, gambling).
    [[CloudXCore shared] setUserKeyValue:@"age_verified" value:@"true"];

    // ============================================
    // 5. ACQUISITION & SOCIAL
    // ============================================
    
    // Paid users often have higher LTV than organic users.
    [[CloudXCore shared] setUserKeyValue:@"install_source" value:@"paid_fb"];
    
    // Verified real human signal (anti-fraud).
    [[CloudXCore shared] setUserKeyValue:@"social_login" value:@"true"];
    
    // Re-engagement potential signal for advertisers.
    [[CloudXCore shared] setUserKeyValue:@"push_opt_in" value:@"true"];
    
    // User plays your other games (portfolio value).
    [[CloudXCore shared] setUserKeyValue:@"cross_promo_user" value:@"true"];
    
    // ============================================
    // APP-LEVEL KEY-VALUES (never cleared)
    // ============================================
    [[CloudXCore shared] setAppKeyValue:@"app_version" value:@"1.2.3"];
    [[CloudXCore shared] setAppKeyValue:@"build_type" value:@"debug"];
    [[CloudXCore shared] setAppKeyValue:@"platform" value:@"ios"];
    [[CloudXCore shared] setAppKeyValue:@"app_category" value:@"IAB9-5"];
    
    [[DemoAppLogger sharedInstance] logMessage:@"✅ HIGH-ROI targeting key-values loaded:"];
    [[DemoAppLogger sharedInstance] logMessage:@""];
    [[DemoAppLogger sharedInstance] logMessage:@"🔥 MONETIZATION (Whale Signals):"];
    [[DemoAppLogger sharedInstance] logMessage:@"   payer_status=whale, iap=50-100, LTV=high"];
    [[DemoAppLogger sharedInstance] logMessage:@""];
    [[DemoAppLogger sharedInstance] logMessage:@"💪 ENGAGEMENT:"];
    [[DemoAppLogger sharedInstance] logMessage:@"   tenure=d30, level=42, loyalty=gold"];
    [[DemoAppLogger sharedInstance] logMessage:@""];
    [[DemoAppLogger sharedInstance] logMessage:@"📺 AD HABITS:"];
    [[DemoAppLogger sharedInstance] logMessage:@"   ad_whale=true, reward_affinity=high"];
    [[DemoAppLogger sharedInstance] logMessage:@""];
    [[DemoAppLogger sharedInstance] logMessage:@"🧪 TEST: Load a banner ad and check bid request for user.ext.data"];
    
    [self refreshDisplayedData];
    
    [self showAlert:@"HIGH-ROI Targeting Loaded" 
            message:@"26 targeting key-values loaded:\n\n"
                    @"🔥 Monetization: payer, iap, LTV\n"
                    @"💪 Engagement: tenure, level, loyalty\n"
                    @"📺 Ad Habits: ad_whale, reward_affinity\n"
                    @"👤 Demographics: age_bracket, device_tier\n\n"
                    @"Load a banner ad to see them in the bid request!"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.displayedUserKVs.count > 0 ? self.displayedUserKVs.count : 1;
    } else {
        return self.displayedAppKVs.count > 0 ? self.displayedAppKVs.count : 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"User-Level (Privacy-Aware)";
    } else {
        return @"App-Level";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KVCell" forIndexPath:indexPath];
    
    NSDictionary *kvDict = indexPath.section == 0 ? self.displayedUserKVs : self.displayedAppKVs;
    NSArray *sortedKeys = [[kvDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    if (sortedKeys.count == 0) {
        cell.textLabel.text = @"No key-value pairs";
        cell.textLabel.textColor = [UIColor secondaryLabelColor];
        cell.textLabel.font = [UIFont italicSystemFontOfSize:14];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        NSString *key = sortedKeys[indexPath.row];
        NSString *value = kvDict[key];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ = %@", key, value];
        cell.textLabel.textColor = [UIColor labelColor];
        cell.textLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *kvDict = indexPath.section == 0 ? self.displayedUserKVs : self.displayedAppKVs;
    if (kvDict.count == 0) return;
    
    NSArray *sortedKeys = [[kvDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSString *key = sortedKeys[indexPath.row];
    NSString *value = kvDict[key];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Key-Value Details" 
                                                                   message:[NSString stringWithFormat:@"Key: %@\nValue: %@\n\nType: %@", 
                                                                           key, value,
                                                                           indexPath.section == 0 ? @"User-Level" : @"App-Level"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *kvDict = indexPath.section == 0 ? self.displayedUserKVs : self.displayedAppKVs;
    return kvDict.count > 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableDictionary *kvDict = indexPath.section == 0 ? self.displayedUserKVs : self.displayedAppKVs;
        NSArray *sortedKeys = [[kvDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSString *key = sortedKeys[indexPath.row];
        
        // Remove from display and state
        [kvDict removeObjectForKey:key];
        
        // Note: We can't remove individual keys from CLXKeyValueState, only clear all
        // So we clear and re-add all remaining keys
        [[CloudXCore shared] clearAllKeyValues];
        for (NSString *k in self.displayedUserKVs) {
            [[CloudXCore shared] setUserKeyValue:k value:self.displayedUserKVs[k]];
        }
        for (NSString *k in self.displayedAppKVs) {
            [[CloudXCore shared] setAppKeyValue:k value:self.displayedAppKVs[k]];
        }
        
        [tableView reloadData];
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"🗑️ Removed key: %@", key]];
    }
}

#pragma mark - Helpers

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

