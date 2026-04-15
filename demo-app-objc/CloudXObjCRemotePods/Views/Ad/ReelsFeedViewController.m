#import "ReelsFeedViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "CLXDemoConfigManager.h"
#import "DemoAppLogger.h"
#import "LogsModalViewController.h"
#import "UserDefaultsSettings.h"

static const NSInteger kReelsAdCount = 5;
static NSString * const kReelsCellIdentifier = @"ReelsCell";

#pragma mark - ReelsAdItem

@interface ReelsAdItem : NSObject
@property (nonatomic, strong, nullable) CLXNativeAdLoader *loader;
@property (nonatomic, strong, nullable) CLXAd *ad;
@property (nonatomic, strong, nullable) CLXNativeAd *nativeAd;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isFailed;
@property (nonatomic, assign) BOOL hideControls;
@property (nonatomic, assign) BOOL isImagePlaceholder;
@end

@implementation ReelsAdItem
@end

#pragma mark - ReelsCell

@interface ReelsCell : UICollectionViewCell
@property (nonatomic, strong) CLXNativeAdView *nativeAdView;
@property (nonatomic, strong) UIView *mediaContainer;
@property (nonatomic, strong) UIView *gradientContainer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UILabel *advertiserLabel;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, strong) UIView *optionsContainer;
@property (nonatomic, strong) UIView *iconContainer;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *slotLabel;
@property (nonatomic, strong) UILabel *videoBadge;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong, nullable) CAGradientLayer *gradient;
@end

@implementation ReelsCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor blackColor];
        self.contentView.clipsToBounds = YES;
        [self buildSubviews];
    }
    return self;
}

- (void)buildSubviews {
    self.nativeAdView = [[CLXNativeAdView alloc] init];
    self.nativeAdView.translatesAutoresizingMaskIntoConstraints = NO;
    self.nativeAdView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.nativeAdView];

    self.mediaContainer = [[UIView alloc] init];
    self.mediaContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.mediaContainer.clipsToBounds = YES;
    [self.nativeAdView addSubview:self.mediaContainer];

    self.gradientContainer = [[UIView alloc] init];
    self.gradientContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.gradientContainer.userInteractionEnabled = NO;
    [self.nativeAdView addSubview:self.gradientContainer];

    self.iconContainer = [[UIView alloc] init];
    self.iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconContainer.clipsToBounds = YES;
    self.iconContainer.layer.cornerRadius = 20;
    [self.nativeAdView addSubview:self.iconContainer];

    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.iconContainer addSubview:self.iconImageView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdView addSubview:self.titleLabel];

    self.advertiserLabel = [[UILabel alloc] init];
    self.advertiserLabel.font = [UIFont systemFontOfSize:13];
    self.advertiserLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    self.advertiserLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdView addSubview:self.advertiserLabel];

    self.bodyLabel = [[UILabel alloc] init];
    self.bodyLabel.font = [UIFont systemFontOfSize:14];
    self.bodyLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    self.bodyLabel.numberOfLines = 2;
    self.bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdView addSubview:self.bodyLabel];

    self.ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.ctaButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.ctaButton.backgroundColor = [UIColor whiteColor];
    [self.ctaButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.ctaButton.layer.cornerRadius = 22;
    self.ctaButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdView addSubview:self.ctaButton];

    self.optionsContainer = [[UIView alloc] init];
    self.optionsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdView addSubview:self.optionsContainer];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spinner.color = [UIColor whiteColor];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.hidesWhenStopped = YES;
    [self.nativeAdView addSubview:self.spinner];

    self.slotLabel = [[UILabel alloc] init];
    self.slotLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    self.slotLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.slotLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdView addSubview:self.slotLabel];

    self.videoBadge = [[UILabel alloc] init];
    self.videoBadge.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightBold];
    self.videoBadge.textColor = [UIColor whiteColor];
    self.videoBadge.textAlignment = NSTextAlignmentCenter;
    self.videoBadge.layer.cornerRadius = 4;
    self.videoBadge.clipsToBounds = YES;
    self.videoBadge.translatesAutoresizingMaskIntoConstraints = NO;
    self.videoBadge.hidden = YES;
    [self.nativeAdView addSubview:self.videoBadge];

    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold];
    self.durationLabel.textColor = [UIColor whiteColor];
    self.durationLabel.textAlignment = NSTextAlignmentCenter;
    self.durationLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.durationLabel.layer.cornerRadius = 4;
    self.durationLabel.clipsToBounds = YES;
    self.durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.durationLabel.hidden = YES;
    [self.nativeAdView addSubview:self.durationLabel];

    self.placeholderImageView = [[UIImageView alloc] init];
    self.placeholderImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.placeholderImageView.clipsToBounds = YES;
    self.placeholderImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderImageView.hidden = YES;
    [self.nativeAdView insertSubview:self.placeholderImageView aboveSubview:self.mediaContainer];

    self.nativeAdView.mediaContentView = self.mediaContainer;
    self.nativeAdView.callToActionButton = self.ctaButton;
    self.nativeAdView.titleLabel = self.titleLabel;
    self.nativeAdView.bodyLabel = self.bodyLabel;
    self.nativeAdView.advertiserLabel = self.advertiserLabel;
    self.nativeAdView.optionsContentView = self.optionsContainer;
    self.nativeAdView.iconContentView = self.iconContainer;
    self.nativeAdView.iconImageView = self.iconImageView;

    CGFloat pad = 16;
    [NSLayoutConstraint activateConstraints:@[
        [self.nativeAdView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.nativeAdView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.nativeAdView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.nativeAdView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

        [self.mediaContainer.topAnchor constraintEqualToAnchor:self.nativeAdView.topAnchor],
        [self.mediaContainer.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor],
        [self.mediaContainer.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor],
        [self.mediaContainer.bottomAnchor constraintEqualToAnchor:self.nativeAdView.bottomAnchor],

        [self.gradientContainer.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor],
        [self.gradientContainer.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor],
        [self.gradientContainer.bottomAnchor constraintEqualToAnchor:self.nativeAdView.bottomAnchor],
        [self.gradientContainer.heightAnchor constraintEqualToConstant:280],

        [self.ctaButton.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor constant:pad],
        [self.ctaButton.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor constant:-pad],
        [self.ctaButton.bottomAnchor constraintEqualToAnchor:self.nativeAdView.safeAreaLayoutGuide.bottomAnchor constant:-pad],
        [self.ctaButton.heightAnchor constraintEqualToConstant:44],

        [self.bodyLabel.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor constant:pad],
        [self.bodyLabel.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor constant:-pad],
        [self.bodyLabel.bottomAnchor constraintEqualToAnchor:self.ctaButton.topAnchor constant:-12],

        [self.iconContainer.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor constant:pad],
        [self.iconContainer.widthAnchor constraintEqualToConstant:40],
        [self.iconContainer.heightAnchor constraintEqualToConstant:40],
        [self.iconContainer.bottomAnchor constraintEqualToAnchor:self.bodyLabel.topAnchor constant:-10],

        [self.iconImageView.topAnchor constraintEqualToAnchor:self.iconContainer.topAnchor],
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.iconContainer.leadingAnchor],
        [self.iconImageView.trailingAnchor constraintEqualToAnchor:self.iconContainer.trailingAnchor],
        [self.iconImageView.bottomAnchor constraintEqualToAnchor:self.iconContainer.bottomAnchor],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.iconContainer.trailingAnchor constant:10],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor constant:-pad],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.iconContainer.centerYAnchor constant:-8],

        [self.advertiserLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.advertiserLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        [self.advertiserLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2],

        [self.optionsContainer.topAnchor constraintEqualToAnchor:self.nativeAdView.safeAreaLayoutGuide.topAnchor constant:8],
        [self.optionsContainer.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor constant:-pad],
        [self.optionsContainer.widthAnchor constraintEqualToConstant:30],
        [self.optionsContainer.heightAnchor constraintEqualToConstant:30],

        [self.spinner.centerXAnchor constraintEqualToAnchor:self.nativeAdView.centerXAnchor],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.nativeAdView.centerYAnchor],

        [self.slotLabel.topAnchor constraintEqualToAnchor:self.nativeAdView.safeAreaLayoutGuide.topAnchor constant:8],
        [self.slotLabel.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor constant:pad],

        [self.videoBadge.leadingAnchor constraintEqualToAnchor:self.slotLabel.trailingAnchor constant:8],
        [self.videoBadge.centerYAnchor constraintEqualToAnchor:self.slotLabel.centerYAnchor],
        [self.videoBadge.heightAnchor constraintEqualToConstant:18],

        [self.durationLabel.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor constant:-pad],
        [self.durationLabel.bottomAnchor constraintEqualToAnchor:self.iconContainer.topAnchor constant:-16],
        [self.durationLabel.heightAnchor constraintEqualToConstant:24],

        [self.placeholderImageView.topAnchor constraintEqualToAnchor:self.nativeAdView.topAnchor],
        [self.placeholderImageView.leadingAnchor constraintEqualToAnchor:self.nativeAdView.leadingAnchor],
        [self.placeholderImageView.trailingAnchor constraintEqualToAnchor:self.nativeAdView.trailingAnchor],
        [self.placeholderImageView.bottomAnchor constraintEqualToAnchor:self.nativeAdView.bottomAnchor],
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.gradient) {
        self.gradient = [CAGradientLayer layer];
        self.gradient.colors = @[
            (id)[UIColor clearColor].CGColor,
            (id)[UIColor colorWithWhite:0 alpha:0.8].CGColor,
        ];
        self.gradient.locations = @[@0.0, @1.0];
        [self.gradientContainer.layer insertSublayer:self.gradient atIndex:0];
    }
    self.gradient.frame = self.gradientContainer.bounds;
}

- (void)configureWithItem:(ReelsAdItem *)item atIndex:(NSInteger)index {
    self.slotLabel.text = [NSString stringWithFormat:@"%ld / %ld", (long)(index + 1), (long)kReelsAdCount];

    if (item.isImagePlaceholder) {
        [self.spinner stopAnimating];
        self.placeholderImageView.hidden = NO;
        self.placeholderImageView.image = [UIImage systemImageNamed:@"photo.artframe"];
        self.placeholderImageView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        self.placeholderImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.mediaContainer.hidden = YES;
        [self showOverlayUI:YES];
        self.titleLabel.text = @"Sample Static Ad";
        self.bodyLabel.text = @"This reel demonstrates the IMAGE badge path";
        self.advertiserLabel.text = @"Demo Advertiser";
        [self.ctaButton setTitle:@"Learn More" forState:UIControlStateNormal];
        self.videoBadge.hidden = NO;
        self.videoBadge.text = @" IMAGE ";
        self.videoBadge.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.7];
        self.durationLabel.hidden = YES;
    } else if (item.isLoaded && item.nativeAd) {
        [self.spinner stopAnimating];
        self.placeholderImageView.hidden = YES;
        self.mediaContainer.hidden = NO;
        [self showOverlayUI:!item.hideControls];
        [self updateVideoBadgeWithNativeAd:item.nativeAd];
    } else if (item.isFailed) {
        [self.spinner stopAnimating];
        self.placeholderImageView.hidden = YES;
        self.mediaContainer.hidden = NO;
        [self showOverlayUI:NO];
        self.titleLabel.text = @"Load Failed";
        self.titleLabel.hidden = NO;
        self.bodyLabel.hidden = YES;
        self.videoBadge.hidden = YES;
        self.durationLabel.hidden = YES;
    } else {
        [self.spinner startAnimating];
        self.placeholderImageView.hidden = YES;
        self.mediaContainer.hidden = NO;
        [self showOverlayUI:NO];
        self.videoBadge.hidden = YES;
        self.durationLabel.hidden = YES;
    }
}

- (void)updateVideoBadgeWithNativeAd:(CLXNativeAd *)nativeAd {
    self.videoBadge.hidden = NO;
    if (nativeAd.isVideoContent) {
        self.videoBadge.text = @" VIDEO ";
        self.videoBadge.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.85];

        if (nativeAd.videoDuration > 0) {
            NSInteger totalSeconds = (NSInteger)nativeAd.videoDuration;
            NSInteger minutes = totalSeconds / 60;
            NSInteger seconds = totalSeconds % 60;
            self.durationLabel.text = [NSString stringWithFormat:@" %ld:%02ld ", (long)minutes, (long)seconds];
            self.durationLabel.hidden = NO;
        } else {
            self.durationLabel.hidden = YES;
        }
    } else {
        self.videoBadge.text = @" STATIC ";
        self.videoBadge.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.7];
        self.durationLabel.hidden = YES;
    }
}

- (void)showOverlayUI:(BOOL)show {
    self.titleLabel.hidden = !show;
    self.advertiserLabel.hidden = !show;
    self.bodyLabel.hidden = !show;
    self.ctaButton.hidden = !show;
    self.gradientContainer.hidden = !show;
    self.iconContainer.hidden = !show;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.spinner stopAnimating];
    [self.nativeAdView prepareForReuse];
    [self.iconContainer addSubview:self.iconImageView];
    self.iconImageView.image = nil;
    self.videoBadge.hidden = YES;
    self.durationLabel.hidden = YES;
    self.placeholderImageView.hidden = YES;
    self.placeholderImageView.image = nil;
    self.mediaContainer.hidden = NO;
}

@end

#pragma mark - ReelsFeedViewController

@interface ReelsFeedViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CLXNativeAdDelegate, CLXAdRevenueDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<ReelsAdItem *> *items;
@property (nonatomic, assign) NSInteger nextLoadIndex;
@property (nonatomic, strong) UIView *settingsPanel;
@property (nonatomic, strong) UISwitch *fullScreenSwitch;
@property (nonatomic, strong) UISwitch *unmutedSwitch;
@property (nonatomic, strong) UISwitch *hideControlsSwitch;
@property (nonatomic, assign) BOOL settingsPanelVisible;
@property (nonatomic, strong) UIButton *gearButton;
@property (nonatomic, strong) UIStackView *settingsBadgesStack;
@end

@implementation ReelsFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Reels Feed";
    self.view.backgroundColor = [UIColor blackColor];

    [self setupCollectionView];
    [self setupAppLogsButton];
    [self setupSettingsPanel];
    [self createItems];
    [self loadNextAd];
}

- (void)dealloc {
    for (ReelsAdItem *item in self.items) {
        [item.loader destroy];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Setup

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.collectionView registerClass:[ReelsCell class] forCellWithReuseIdentifier:kReelsCellIdentifier];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupAppLogsButton {
    UIButton *logsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [logsButton setTitle:@"App Logs" forState:UIControlStateNormal];
    logsButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    logsButton.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.9];
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

- (void)setupSettingsPanel {
    self.gearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *iconConfig = [UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
    UIImage *gearIcon = [UIImage systemImageNamed:@"slider.horizontal.3" withConfiguration:iconConfig];
    [self.gearButton setImage:gearIcon forState:UIControlStateNormal];
    [self.gearButton setTitle:@" Video Config" forState:UIControlStateNormal];
    self.gearButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    self.gearButton.tintColor = [UIColor whiteColor];
    self.gearButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.gearButton.layer.cornerRadius = 14;
    self.gearButton.contentEdgeInsets = UIEdgeInsetsMake(6, 10, 6, 12);
    self.gearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.gearButton addTarget:self action:@selector(toggleSettingsPanel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.gearButton];

    self.settingsBadgesStack = [[UIStackView alloc] init];
    self.settingsBadgesStack.axis = UILayoutConstraintAxisHorizontal;
    self.settingsBadgesStack.spacing = 4;
    self.settingsBadgesStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.settingsBadgesStack];

    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurView.layer.cornerRadius = 12;
    blurView.clipsToBounds = YES;
    blurView.translatesAutoresizingMaskIntoConstraints = NO;

    self.settingsPanel = [[UIView alloc] init];
    self.settingsPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.settingsPanel.alpha = 0;
    self.settingsPanel.hidden = YES;
    [self.view addSubview:self.settingsPanel];
    [self.settingsPanel addSubview:blurView];

    [NSLayoutConstraint activateConstraints:@[
        [blurView.topAnchor constraintEqualToAnchor:self.settingsPanel.topAnchor],
        [blurView.leadingAnchor constraintEqualToAnchor:self.settingsPanel.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.settingsPanel.trailingAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:self.settingsPanel.bottomAnchor],
    ]];

    UILabel *header = [[UILabel alloc] init];
    header.text = @"Video Config";
    header.font = [UIFont boldSystemFontOfSize:14];
    header.textColor = [UIColor whiteColor];

    self.fullScreenSwitch = [[UISwitch alloc] init];
    self.fullScreenSwitch.on = YES;
    self.fullScreenSwitch.transform = CGAffineTransformMakeScale(0.7, 0.7);

    self.unmutedSwitch = [[UISwitch alloc] init];
    self.unmutedSwitch.on = YES;
    self.unmutedSwitch.transform = CGAffineTransformMakeScale(0.7, 0.7);

    self.hideControlsSwitch = [[UISwitch alloc] init];
    self.hideControlsSwitch.on = YES;
    self.hideControlsSwitch.transform = CGAffineTransformMakeScale(0.7, 0.7);

    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [reloadButton setTitle:@"Reload Ads" forState:UIControlStateNormal];
    reloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    reloadButton.backgroundColor = [UIColor systemBlueColor];
    [reloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    reloadButton.layer.cornerRadius = 8;
    reloadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [reloadButton addTarget:self action:@selector(reloadAdsWithSettings) forControlEvents:UIControlEventTouchUpInside];
    [reloadButton.heightAnchor constraintEqualToConstant:32].active = YES;

    UILabel *disclaimer = [[UILabel alloc] init];
    disclaimer.text = @"Requires FAN SDK 6.21.1+ for Meta native ads";
    disclaimer.font = [UIFont italicSystemFontOfSize:9];
    disclaimer.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
    disclaimer.numberOfLines = 0;
    disclaimer.textAlignment = NSTextAlignmentCenter;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        header,
        [self settingsRowWithLabel:@"Disable Fullscreen" toggle:self.fullScreenSwitch],
        [self settingsRowWithLabel:@"Start Unmuted" toggle:self.unmutedSwitch],
        [self settingsRowWithLabel:@"Hide Controls" toggle:self.hideControlsSwitch],
        reloadButton,
        disclaimer
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.settingsPanel addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.gearButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:44],
        [self.gearButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.gearButton.heightAnchor constraintEqualToConstant:28],

        [self.settingsBadgesStack.topAnchor constraintEqualToAnchor:self.gearButton.bottomAnchor constant:6],
        [self.settingsBadgesStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],

        [self.settingsPanel.topAnchor constraintEqualToAnchor:self.settingsBadgesStack.bottomAnchor constant:6],
        [self.settingsPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.settingsPanel.widthAnchor constraintEqualToConstant:220],
        [stack.topAnchor constraintEqualToAnchor:self.settingsPanel.topAnchor constant:12],
        [stack.leadingAnchor constraintEqualToAnchor:self.settingsPanel.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:self.settingsPanel.trailingAnchor constant:-12],
        [stack.bottomAnchor constraintEqualToAnchor:self.settingsPanel.bottomAnchor constant:-12],
    ]];

    [self updateSettingsBadges];
}

- (UIStackView *)settingsRowWithLabel:(NSString *)text toggle:(UISwitch *)toggle {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, toggle]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.distribution = UIStackViewDistributionEqualSpacing;
    return row;
}

- (void)updateSettingsBadges {
    for (UIView *v in self.settingsBadgesStack.arrangedSubviews) { [v removeFromSuperview]; }

    BOOL disableFS = self.fullScreenSwitch ? self.fullScreenSwitch.isOn : YES;
    BOOL unmuted   = self.unmutedSwitch ? self.unmutedSwitch.isOn : YES;
    BOOL hideCtrl  = self.hideControlsSwitch ? self.hideControlsSwitch.isOn : YES;

    if (disableFS)  [self.settingsBadgesStack addArrangedSubview:[self badgeWithText:@"No FS" color:[UIColor systemPurpleColor]]];
    if (unmuted)    [self.settingsBadgesStack addArrangedSubview:[self badgeWithText:@"Unmuted" color:[UIColor systemGreenColor]]];
    if (hideCtrl)   [self.settingsBadgesStack addArrangedSubview:[self badgeWithText:@"No Ctrl" color:[UIColor systemOrangeColor]]];
}

- (UILabel *)badgeWithText:(NSString *)text color:(UIColor *)color {
    UILabel *badge = [[UILabel alloc] init];
    badge.text = [NSString stringWithFormat:@"  %@  ", text];
    badge.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
    badge.textColor = [UIColor whiteColor];
    badge.backgroundColor = [color colorWithAlphaComponent:0.8];
    badge.layer.cornerRadius = 8;
    badge.clipsToBounds = YES;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [badge.heightAnchor constraintEqualToConstant:16].active = YES;
    return badge;
}

- (void)toggleSettingsPanel {
    self.settingsPanelVisible = !self.settingsPanelVisible;
    if (self.settingsPanelVisible) {
        self.settingsPanel.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{ self.settingsPanel.alpha = 1.0; }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.settingsPanel.alpha = 0;
        } completion:^(BOOL finished) { self.settingsPanel.hidden = YES; }];
    }
}

- (void)reloadAdsWithSettings {
    for (ReelsAdItem *item in self.items) { [item.loader destroy]; }
    [self.items removeAllObjects];
    self.nextLoadIndex = 0;

    BOOL hideCtrl = self.hideControlsSwitch.isOn;
    for (NSInteger i = 0; i < kReelsAdCount; i++) {
        ReelsAdItem *item = [[ReelsAdItem alloc] init];
        if (i % 2 == 1) {
            item.isImagePlaceholder = YES;
            item.isLoaded = YES;
        } else {
            item.loader = [[CloudXCore shared] createNativeAdLoaderWithAdUnitIdentifier:[self adUnitId]];
            item.loader.nativeAdDelegate = self;
            item.loader.revenueDelegate = self;
            item.loader.placement = [NSString stringWithFormat:@"reels_slot_%ld", (long)i];
            item.loader.disableVideoFullScreen = self.fullScreenSwitch.isOn;
            item.loader.startVideoUnmuted = self.unmutedSwitch.isOn;
            item.loader.hideVideoMediaControls = hideCtrl;
            item.hideControls = hideCtrl;
        }
        [self.items addObject:item];
    }

    [self.collectionView reloadData];
    [self loadNextAd];
    [self toggleSettingsPanel];
    [self updateSettingsBadges];

    NSString *reloadMsg = [NSString stringWithFormat:@"🔄 Reels reloading with: fullscreen=%@, unmuted=%@, hideControls=%@",
          self.fullScreenSwitch.isOn ? @"OFF" : @"ON",
          self.unmutedSwitch.isOn ? @"YES" : @"NO",
          self.hideControlsSwitch.isOn ? @"YES" : @"NO"];
    [[DemoAppLogger sharedInstance] logMessage:reloadMsg];
}

- (NSString *)adUnitId {
    NSString *adUnitId = [[CLXDemoConfigManager sharedManager] currentConfig].nativeAdUnitId;
    if ([UserDefaultsSettings sharedSettings].nativeMediumAdUnitId.length > 0) {
        adUnitId = [UserDefaultsSettings sharedSettings].nativeMediumAdUnitId;
    }
    return adUnitId;
}

- (void)createItems {
    self.items = [NSMutableArray arrayWithCapacity:kReelsAdCount];
    self.nextLoadIndex = 0;

    BOOL disableFS = self.fullScreenSwitch ? self.fullScreenSwitch.isOn : YES;
    BOOL unmuted = self.unmutedSwitch ? self.unmutedSwitch.isOn : YES;
    BOOL hideCtrl = self.hideControlsSwitch ? self.hideControlsSwitch.isOn : YES;

    for (NSInteger i = 0; i < kReelsAdCount; i++) {
        ReelsAdItem *item = [[ReelsAdItem alloc] init];
        if (i % 2 == 1) {
            item.isImagePlaceholder = YES;
            item.isLoaded = YES;
        } else {
            item.loader = [[CloudXCore shared] createNativeAdLoaderWithAdUnitIdentifier:[self adUnitId]];
            item.loader.nativeAdDelegate = self;
            item.loader.revenueDelegate = self;
            item.loader.placement = [NSString stringWithFormat:@"reels_slot_%ld", (long)i];
            item.loader.disableVideoFullScreen = disableFS;
            item.loader.startVideoUnmuted = unmuted;
            item.loader.hideVideoMediaControls = hideCtrl;
            item.hideControls = hideCtrl;
        }
        [self.items addObject:item];
    }
}

#pragma mark - Sequential Loading

- (void)loadNextAd {
    while (self.nextLoadIndex < kReelsAdCount && self.items[self.nextLoadIndex].isImagePlaceholder) {
        self.nextLoadIndex++;
    }
    if (self.nextLoadIndex >= kReelsAdCount) return;

    ReelsAdItem *item = self.items[self.nextLoadIndex];
    item.isLoading = YES;
    [item.loader loadAd];
}

#pragma mark - CLXNativeAdDelegate

- (void)didLoadNativeAd:(nullable CLXNativeAdView *)nativeAdView forAd:(CLXAd *)ad {
    NSInteger idx = self.nextLoadIndex;
    if (idx >= kReelsAdCount) return;

    ReelsAdItem *item = self.items[idx];
    item.isLoading = NO;
    item.isLoaded = YES;
    item.ad = ad;
    item.nativeAd = ad.nativeAd;

    NSString *creativeType = ad.nativeAd.isVideoContent ? @"video" : @"static";
    NSString *msg = [NSString stringWithFormat:@"✅ Reels didLoadNativeAd (slot %ld, %@, duration=%.1fs)", (long)idx, creativeType, ad.nativeAd.videoDuration];
    [[DemoAppLogger sharedInstance] logAdEvent:msg ad:ad];

    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:0]]];

    self.nextLoadIndex++;
    [self loadNextAd];
}

- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitId error:(CLXError *)error {
    NSInteger idx = self.nextLoadIndex;
    if (idx >= kReelsAdCount) return;

    ReelsAdItem *item = self.items[idx];
    item.isLoading = NO;
    item.isFailed = YES;

    NSString *msg = [NSString stringWithFormat:@"❌ Reels didFailToLoadNativeAd (slot %ld): %@", (long)idx, error.localizedDescription];
    [[DemoAppLogger sharedInstance] logMessage:msg];

    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:0]]];

    self.nextLoadIndex++;
    [self loadNextAd];
}

- (void)didClickNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Reels didClickNativeAd" ad:ad];
}

- (void)didExpireNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"⏰ Reels didExpireNativeAd" ad:ad];
}

- (void)didCloseNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🚪 Reels didCloseNativeAd — user reported/hid ad via AdChoices" ad:ad];

    NSInteger closedIdx = NSNotFound;
    for (NSInteger i = 0; i < self.items.count; i++) {
        if (self.items[i].ad == ad) { closedIdx = i; break; }
    }

    [self showDismissToast];

    if (closedIdx != NSNotFound && closedIdx + 1 < kReelsAdCount) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            NSIndexPath *next = [NSIndexPath indexPathForItem:closedIdx + 1 inSection:0];
            [strongSelf.collectionView scrollToItemAtIndexPath:next atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
        });
    }
}

- (void)showDismissToast {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = @"  Ad reported by user — moving to next  ";
    toast.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 16;
    toast.clipsToBounds = YES;
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.alpha = 0;
    [self.view addSubview:toast];

    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [toast.heightAnchor constraintEqualToConstant:32],
    ]];

    [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 1.0; }];

    __weak UILabel *weakToast = toast;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            weakToast.alpha = 0;
        } completion:^(BOOL finished) {
            [weakToast removeFromSuperview];
        }];
    });
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Reels didPayRevenueForAd" ad:ad];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kReelsAdCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ReelsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReelsCellIdentifier forIndexPath:indexPath];
    ReelsAdItem *item = self.items[indexPath.item];
    [cell configureWithItem:item atIndex:indexPath.item];

    if (item.isLoaded && !item.isImagePlaceholder && item.ad) {
        [item.loader renderNativeAdView:cell.nativeAdView withAd:item.ad];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

@end
