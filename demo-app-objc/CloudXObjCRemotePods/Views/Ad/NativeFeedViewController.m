#import "NativeFeedViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "CLXDemoConfigManager.h"
#import "DemoAppLogger.h"
#import "LogsModalViewController.h"
#import "UserDefaultsSettings.h"

static const NSInteger kAdCount = 10;
static NSString * const kAdCellIdentifier = @"NativeAdCell";

typedef NS_ENUM(NSInteger, NativeAdCreativeType) {
    NativeAdCreativeTypeUnknown,
    NativeAdCreativeTypeImage,
    NativeAdCreativeTypeVideoLandscape,
    NativeAdCreativeTypeVideoPortrait,
};

#pragma mark - NativeAdFeedItem

@interface NativeAdFeedItem : NSObject
@property (nonatomic, strong) CLXNativeAdLoader *loader;
@property (nonatomic, strong, nullable) CLXNativeAdView *adView;
@property (nonatomic, strong, nullable) CLXAd *ad;
@property (nonatomic, assign) NativeAdCreativeType creativeType;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isFailed;
@end

@implementation NativeAdFeedItem
@end

#pragma mark - NativeFeedViewController

@interface NativeFeedViewController () <UITableViewDataSource, UITableViewDelegate, CLXNativeAdDelegate, CLXAdRevenueDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NativeAdFeedItem *> *feedItems;
@property (nonatomic, assign) NSInteger nextLoadIndex;
@end

@implementation NativeFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Native Feed";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupTableView];
    [self setupAppLogsButton];
    [self createFeedItems];
    [self loadNextAd];
}

- (void)dealloc {
    for (NativeAdFeedItem *item in self.feedItems) {
        [item.loader destroy];
    }
}

#pragma mark - Setup

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kAdCellIdentifier];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupAppLogsButton {
    UIButton *logsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [logsButton setTitle:@"App Logs" forState:UIControlStateNormal];
    logsButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    logsButton.backgroundColor = [UIColor systemOrangeColor];
    [logsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    logsButton.layer.cornerRadius = 6;
    logsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [logsButton addTarget:self action:@selector(showLogsModal) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logsButton];

    [NSLayoutConstraint activateConstraints:@[
        [logsButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [logsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [logsButton.widthAnchor constraintEqualToConstant:90],
        [logsButton.heightAnchor constraintEqualToConstant:30],
    ]];
}

- (void)showLogsModal {
    LogsModalViewController *logsModal = [[LogsModalViewController alloc] initWithTitle:@"Logs"];
    logsModal.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:logsModal animated:YES completion:nil];
}

- (NSString *)adUnitId {
    NSString *adUnitId = [[CLXDemoConfigManager sharedManager] currentConfig].nativeAdUnitId;
    if ([UserDefaultsSettings sharedSettings].nativeMediumAdUnitId.length > 0) {
        adUnitId = [UserDefaultsSettings sharedSettings].nativeMediumAdUnitId;
    }
    return adUnitId;
}

- (void)createFeedItems {
    self.feedItems = [NSMutableArray arrayWithCapacity:kAdCount];
    self.nextLoadIndex = 0;

    for (NSInteger i = 0; i < kAdCount; i++) {
        NativeAdFeedItem *item = [[NativeAdFeedItem alloc] init];
        item.loader = [[CloudXCore shared] createNativeAdLoaderWithAdUnitIdentifier:[self adUnitId]];
        item.loader.nativeAdDelegate = self;
        item.loader.revenueDelegate = self;
        item.loader.placement = [NSString stringWithFormat:@"feed_slot_%ld", (long)i];
        item.creativeType = NativeAdCreativeTypeUnknown;
        [self.feedItems addObject:item];
    }
}

#pragma mark - Sequential Loading

- (void)loadNextAd {
    if (self.nextLoadIndex >= kAdCount) return;

    NativeAdFeedItem *item = self.feedItems[self.nextLoadIndex];
    item.isLoading = YES;
    [item.loader loadAd];
}

- (nullable NativeAdFeedItem *)feedItemForLoader:(CLXNativeAdLoader *)loader {
    for (NativeAdFeedItem *item in self.feedItems) {
        if (item.loader == loader) return item;
    }
    return nil;
}

- (NSInteger)indexForLoader:(CLXNativeAdLoader *)loader {
    for (NSInteger i = 0; i < self.feedItems.count; i++) {
        if (self.feedItems[i].loader == loader) return i;
    }
    return NSNotFound;
}

#pragma mark - Creative Type Detection

- (NativeAdCreativeType)detectCreativeTypeFromAd:(CLXAd *)ad nativeAdView:(CLXNativeAdView *)adView {
    CLXNativeAd *nativeAd = ad.nativeAd;
    if (!nativeAd) return NativeAdCreativeTypeUnknown;

    if (nativeAd.isVideoContent) {
        CGFloat ar = nativeAd.mediaContentAspectRatio;
        return (ar < 1.0) ? NativeAdCreativeTypeVideoPortrait : NativeAdCreativeTypeVideoLandscape;
    }

    return (nativeAd.mediaContentAspectRatio > 0) ? NativeAdCreativeTypeImage : NativeAdCreativeTypeUnknown;
}

- (NSString *)badgeTextForCreativeType:(NativeAdCreativeType)type {
    switch (type) {
        case NativeAdCreativeTypeImage: return @"IMAGE";
        case NativeAdCreativeTypeVideoLandscape: return @"VIDEO 16:9";
        case NativeAdCreativeTypeVideoPortrait: return @"REELS 9:16";
        case NativeAdCreativeTypeUnknown: return @"UNKNOWN";
    }
}

- (UIColor *)badgeColorForCreativeType:(NativeAdCreativeType)type {
    switch (type) {
        case NativeAdCreativeTypeImage: return [UIColor systemBlueColor];
        case NativeAdCreativeTypeVideoLandscape: return [UIColor systemOrangeColor];
        case NativeAdCreativeTypeVideoPortrait: return [UIColor systemPurpleColor];
        case NativeAdCreativeTypeUnknown: return [UIColor systemGrayColor];
    }
}

#pragma mark - CLXNativeAdDelegate

- (void)didLoadNativeAd:(nullable CLXNativeAdView *)nativeAdView forAd:(CLXAd *)ad {
    CLXNativeAdLoader *loader = nil;
    for (NativeAdFeedItem *item in self.feedItems) {
        if (item.isLoading && !item.isLoaded) {
            loader = item.loader;
            break;
        }
    }

    NSInteger idx = self.nextLoadIndex;
    if (idx >= kAdCount) return;

    NativeAdFeedItem *item = self.feedItems[idx];
    item.isLoading = NO;
    item.isLoaded = YES;
    item.ad = ad;

    if (nativeAdView) {
        item.adView = nativeAdView;
    } else {
        CLXNativeAdView *templateView = [CLXNativeAdView viewFromAd:ad.nativeAd];
        [item.loader renderNativeAdView:templateView withAd:ad];
        item.adView = templateView;
    }

    item.creativeType = [self detectCreativeTypeFromAd:ad nativeAdView:item.adView];

    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"✅ Feed slot %ld loaded: %@", (long)idx, [self badgeTextForCreativeType:item.creativeType]]];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]
                          withRowAnimation:UITableViewRowAnimationFade];

    self.nextLoadIndex++;
    [self loadNextAd];
}

- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitId error:(CLXError *)error {
    NSInteger idx = self.nextLoadIndex;
    if (idx >= kAdCount) return;

    NativeAdFeedItem *item = self.feedItems[idx];
    item.isLoading = NO;
    item.isFailed = YES;

    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Feed slot %ld failed: %@", (long)idx, error.localizedDescription]];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]
                          withRowAnimation:UITableViewRowAnimationFade];

    self.nextLoadIndex++;
    [self loadNextAd];
}

- (void)didClickNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Feed didClickNativeAd" ad:ad];
}

- (void)didExpireNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"⏰ Feed didExpireNativeAd" ad:ad];
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Feed didPayRevenueForAd" ad:ad];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kAdCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAdCellIdentifier forIndexPath:indexPath];

    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    NativeAdFeedItem *item = self.feedItems[indexPath.row];

    if (item.isLoaded && item.adView) {
        item.adView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:item.adView];

        [NSLayoutConstraint activateConstraints:@[
            [item.adView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
            [item.adView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:12],
            [item.adView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-12],
            [item.adView.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],
        ]];

        UILabel *badge = [[UILabel alloc] init];
        badge.text = [NSString stringWithFormat:@" %@ ", [self badgeTextForCreativeType:item.creativeType]];
        badge.font = [UIFont boldSystemFontOfSize:11];
        badge.textColor = [UIColor whiteColor];
        badge.backgroundColor = [self badgeColorForCreativeType:item.creativeType];
        badge.layer.cornerRadius = 4;
        badge.clipsToBounds = YES;
        badge.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:badge];

        UILabel *slotLabel = [[UILabel alloc] init];
        slotLabel.text = [NSString stringWithFormat:@"Slot %ld", (long)indexPath.row];
        slotLabel.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightMedium];
        slotLabel.textColor = [UIColor tertiaryLabelColor];
        slotLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:slotLabel];

        [NSLayoutConstraint activateConstraints:@[
            [badge.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:14],
            [badge.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-18],
            [slotLabel.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:14],
            [slotLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:18],
        ]];
    } else if (item.isFailed) {
        UILabel *errorLabel = [[UILabel alloc] init];
        errorLabel.text = [NSString stringWithFormat:@"Slot %ld — Load Failed", (long)indexPath.row];
        errorLabel.textColor = [UIColor systemRedColor];
        errorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        errorLabel.textAlignment = NSTextAlignmentCenter;
        errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:errorLabel];
        [NSLayoutConstraint activateConstraints:@[
            [errorLabel.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor],
            [errorLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
        ]];
    } else {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [spinner startAnimating];
        [cell.contentView addSubview:spinner];

        UILabel *loadingLabel = [[UILabel alloc] init];
        loadingLabel.text = [NSString stringWithFormat:@"Slot %ld — Loading...", (long)indexPath.row];
        loadingLabel.textColor = [UIColor secondaryLabelColor];
        loadingLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:loadingLabel];

        [NSLayoutConstraint activateConstraints:@[
            [spinner.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [spinner.trailingAnchor constraintEqualToAnchor:loadingLabel.leadingAnchor constant:-8],
            [loadingLabel.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor constant:12],
            [loadingLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
        ]];
    }

    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NativeAdFeedItem *item = self.feedItems[indexPath.row];

    if (item.isLoaded) {
        if (item.creativeType == NativeAdCreativeTypeVideoPortrait) {
            return 600;
        }
        return 400;
    }

    return 80;
}

@end
