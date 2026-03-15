/*
 * ILRD demo screen -- loads and shows AppLovin MAX ads directly.
 * ILRD events flow through the SDK's CLXIlrdTracker and appear in logs.
 * Matches Android's IlrdFragment.
 */

#import "IlrdViewController.h"
#import "DemoAppLogger.h"
@import AppLovinSDK;

static NSString *const kBannerAdUnitId = @"f4261a9d26d33189";
static NSString *const kMrecAdUnitId = @"9511c403eb8144d6";
static NSString *const kInterstitialAdUnitId = @"11bec1553cb11324";
static NSString *const kRewardedAdUnitId = @"3f9c22745dec8f18";

@interface IlrdViewController () <MAAdViewAdDelegate, MAAdDelegate, MARewardedAdDelegate>
@property (nonatomic, strong, nullable) MAAdView *bannerAd;
@property (nonatomic, strong, nullable) MAAdView *mrecAd;
@property (nonatomic, strong, nullable) MAInterstitialAd *interstitialAd;
@property (nonatomic, strong, nullable) MARewardedAd *rewardedAd;
@property (nonatomic, strong) UIStackView *adContainer;
@end

@implementation IlrdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"ILRD";

    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 12;
    buttonStack.alignment = UIStackViewAlignmentCenter;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];

    [buttonStack addArrangedSubview:[self buttonWithTitle:@"Show Banner" action:@selector(showBanner)]];
    [buttonStack addArrangedSubview:[self buttonWithTitle:@"Show MREC" action:@selector(showMrec)]];
    [buttonStack addArrangedSubview:[self buttonWithTitle:@"Show Interstitial" action:@selector(showInterstitial)]];
    [buttonStack addArrangedSubview:[self buttonWithTitle:@"Show Rewarded" action:@selector(showRewarded)]];

    /* Container for banner/MREC ad views at the bottom */
    _adContainer = [[UIStackView alloc] init];
    _adContainer.axis = UILayoutConstraintAxisVertical;
    _adContainer.alignment = UIStackViewAlignmentCenter;
    _adContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_adContainer];

    [NSLayoutConstraint activateConstraints:@[
        [buttonStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buttonStack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [_adContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_adContainer.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
    ]];
}

- (void)dealloc {
    [self removeBannerAd:_bannerAd];
    [self removeBannerAd:_mrecAd];
    _interstitialAd = nil;
    _rewardedAd = nil;
}

#pragma mark - Button Actions

- (void)showBanner {
    [self removeBannerAd:_bannerAd];
    _bannerAd = [self createAdViewWithAdUnitId:kBannerAdUnitId format:MAAdFormat.banner];
}

- (void)showMrec {
    [self removeBannerAd:_mrecAd];
    _mrecAd = [self createAdViewWithAdUnitId:kMrecAdUnitId format:MAAdFormat.mrec];
}

- (void)showInterstitial {
    _interstitialAd = nil;
    _interstitialAd = [[MAInterstitialAd alloc] initWithAdUnitIdentifier:kInterstitialAdUnitId];
    _interstitialAd.delegate = self;
    [[DemoAppLogger sharedInstance] logMessage:@"Loading interstitial..."];
    [_interstitialAd loadAd];
}

- (void)showRewarded {
    _rewardedAd = nil;
    _rewardedAd = [MARewardedAd sharedWithAdUnitIdentifier:kRewardedAdUnitId];
    _rewardedAd.delegate = self;
    [[DemoAppLogger sharedInstance] logMessage:@"Loading rewarded..."];
    [_rewardedAd loadAd];
}

#pragma mark - Banner/MREC Helpers

- (MAAdView *)createAdViewWithAdUnitId:(NSString *)adUnitId format:(MAAdFormat *)format {
    MAAdView *ad = [[MAAdView alloc] initWithAdUnitIdentifier:adUnitId adFormat:format];
    ad.delegate = self;
    ad.translatesAutoresizingMaskIntoConstraints = NO;
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Loading %@...", format.label]];
    [ad loadAd];
    return ad;
}

- (void)removeBannerAd:(MAAdView *)ad {
    if (!ad) return;
    [ad removeFromSuperview];
    [ad stopAutoRefresh];
}

#pragma mark - MAAdViewAdDelegate (Banner / MREC)

- (void)didLoadAd:(MAAd *)ad {
    NSString *format = ad.format.label;
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"%@ loaded: %@", format, ad.networkName]];

    if (ad.format == MAAdFormat.banner && _bannerAd) {
        [_adContainer addArrangedSubview:_bannerAd];
        [NSLayoutConstraint activateConstraints:@[
            [_bannerAd.widthAnchor constraintEqualToConstant:320],
            [_bannerAd.heightAnchor constraintEqualToConstant:50],
        ]];
    } else if (ad.format == MAAdFormat.mrec && _mrecAd) {
        [_adContainer addArrangedSubview:_mrecAd];
        [NSLayoutConstraint activateConstraints:@[
            [_mrecAd.widthAnchor constraintEqualToConstant:300],
            [_mrecAd.heightAnchor constraintEqualToConstant:250],
        ]];
    } else if (ad.format == MAAdFormat.interstitial) {
        [[DemoAppLogger sharedInstance] logMessage:@"Interstitial loaded, showing..."];
        [_interstitialAd showAdForPlacement:nil customData:nil viewController:self];
    } else if (ad.format == MAAdFormat.rewarded) {
        [[DemoAppLogger sharedInstance] logMessage:@"Rewarded loaded, showing..."];
        [_rewardedAd showAdForPlacement:nil customData:nil viewController:self];
    }
}

- (void)didDisplayAd:(MAAd *)ad {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"%@ displayed", ad.format.label]];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Load failed (%@): %@", adUnitIdentifier, error.message]];
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"%@ display failed: %@", ad.format.label, error.message]];
}

- (void)didClickAd:(MAAd *)ad {}
- (void)didHideAd:(MAAd *)ad {}
- (void)didExpandAd:(MAAd *)ad {}
- (void)didCollapseAd:(MAAd *)ad {}

#pragma mark - MARewardedAdDelegate

- (void)didRewardUserForAd:(MAAd *)ad withReward:(MAReward *)reward {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"User rewarded: %ld %@", (long)reward.amount, reward.label]];
}

#pragma mark - Helpers

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:200],
        [button.heightAnchor constraintEqualToConstant:44],
    ]];
    return button;
}

@end
