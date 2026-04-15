#import "NativeViewController.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"
#import "CLXDemoConfigManager.h"
#import "UserDefaultsSettings.h"
#import "NSError+DemoDescription.h"

typedef NS_ENUM(NSInteger, NativeFlow) {
    NativeFlowTemplate = 0,
    NativeFlowManual = 1,
    NativeFlowLateBinding = 2,
};

@interface NativeViewController ()
@property (nonatomic, strong, nullable) CLXNativeAdLoader *nativeAdLoader;
@property (nonatomic, strong, nullable) CLXNativeAdView *nativeAdView;
@property (nonatomic, strong, nullable) CLXAd *loadedAd;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIView *adContainerView;
@property (nonatomic, assign) AdState adState;
@property (nonatomic, strong) UserDefaultsSettings *settings;
@property (nonatomic, assign) NativeFlow activeFlow;
@property (nonatomic, strong) UISegmentedControl *flowPicker;
@property (nonatomic, strong) UILabel *flowDescription;
@property (nonatomic, strong) UIButton *loadButton;
@property (nonatomic, strong) UIButton *bindButton;
@property (nonatomic, strong) UIButton *destroyButton;
@property (nonatomic, strong) UILabel *flowBanner;
@property (nonatomic, strong, nullable) CLXAd *preloadedAd;
@end

@implementation NativeViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Native";
    self.settings = [UserDefaultsSettings sharedSettings];
    self.activeFlow = NativeFlowTemplate;
    [self setupUI];
    [self updateStatusUIWithState:AdStateNoAd];
    [self flowPickerChanged];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetAdState];
}

- (void)dealloc {
    [self.nativeAdLoader destroy];
}

#pragma mark - UI Setup

- (void)setupUI {
    self.flowDescription = [[UILabel alloc] init];
    self.flowDescription.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.flowDescription.textColor = [UIColor labelColor];
    self.flowDescription.textAlignment = NSTextAlignmentLeft;
    self.flowDescription.numberOfLines = 0;
    self.flowDescription.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.flowDescription];

    [NSLayoutConstraint activateConstraints:@[
        [self.flowDescription.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.flowDescription.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.flowDescription.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-140],
        [self.flowDescription.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:90],
    ]];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 6;
    self.contentStack.alignment = UIStackViewAlignmentFill;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentStack];

    self.flowPicker = [[UISegmentedControl alloc] initWithItems:@[@"A: Template", @"B: Manual", @"C: Late-Bind"]];
    self.flowPicker.selectedSegmentIndex = 0;
    [self.flowPicker addTarget:self action:@selector(flowPickerChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentStack addArrangedSubview:self.flowPicker];

    UIStackView *buttonRow = [[UIStackView alloc] init];
    buttonRow.axis = UILayoutConstraintAxisHorizontal;
    buttonRow.spacing = 8;
    buttonRow.alignment = UIStackViewAlignmentCenter;
    buttonRow.distribution = UIStackViewDistributionFill;

    UIView *leftSpacer = [[UIView alloc] init];
    UIView *rightSpacer = [[UIView alloc] init];

    self.loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loadButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.loadButton.layer.cornerRadius = 8;
    self.loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadButton addTarget:self action:@selector(loadAction) forControlEvents:UIControlEventTouchUpInside];

    self.destroyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.destroyButton setTitle:@"Destroy" forState:UIControlStateNormal];
    [self.destroyButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    self.destroyButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];

    [self.destroyButton addTarget:self action:@selector(destroyAd) forControlEvents:UIControlEventTouchUpInside];

    [buttonRow addArrangedSubview:leftSpacer];
    [buttonRow addArrangedSubview:self.loadButton];
    [buttonRow addArrangedSubview:self.destroyButton];
    [buttonRow addArrangedSubview:rightSpacer];
    [self.contentStack addArrangedSubview:buttonRow];

    [NSLayoutConstraint activateConstraints:@[
        [self.loadButton.widthAnchor constraintEqualToConstant:200],
        [self.loadButton.heightAnchor constraintEqualToConstant:36],
        [leftSpacer.widthAnchor constraintEqualToAnchor:rightSpacer.widthAnchor],
    ]];

    self.bindButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.bindButton setTitle:@"Step 2: Bind & Display" forState:UIControlStateNormal];
    [self.bindButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.bindButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.bindButton.backgroundColor = [UIColor systemTealColor];
    self.bindButton.layer.cornerRadius = 8;
    self.bindButton.hidden = YES;
    self.bindButton.alpha = 0;
    [self.bindButton addTarget:self action:@selector(bindPreloadedAd) forControlEvents:UIControlEventTouchUpInside];
    [self.contentStack addArrangedSubview:self.bindButton];
    [self.bindButton.heightAnchor constraintEqualToConstant:36].active = YES;

    self.flowBanner = [[UILabel alloc] init];
    self.flowBanner.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightBold];
    self.flowBanner.textAlignment = NSTextAlignmentCenter;
    self.flowBanner.numberOfLines = 0;
    self.flowBanner.textColor = [UIColor secondaryLabelColor];
    [self.contentStack addArrangedSubview:self.flowBanner];

    self.adContainerView = [[UIView alloc] init];
    self.adContainerView.clipsToBounds = YES;
    [self.contentStack addArrangedSubview:self.adContainerView];

    [self.adContainerView.heightAnchor constraintGreaterThanOrEqualToConstant:400].active = YES;

    CGFloat pad = 16;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.statusStack.topAnchor constant:-4],

        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:pad],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-pad],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-pad],
        [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-pad * 2],
    ]];
}

- (void)flowPickerChanged {
    self.activeFlow = (NativeFlow)self.flowPicker.selectedSegmentIndex;

    switch (self.activeFlow) {
        case NativeFlowTemplate:
            self.flowDescription.text = @"Template — SDK auto-generates the ad view. Zero custom UI code. Just load and the SDK handles layout.";
            [self.loadButton setTitle:@"Load Ad" forState:UIControlStateNormal];
            self.loadButton.backgroundColor = [UIColor systemGreenColor];
            break;
        case NativeFlowManual:
            self.flowDescription.text = @"Manual — Publisher builds a fully custom layout. Every element is positioned and styled by your code.";
            [self.loadButton setTitle:@"Load Ad" forState:UIControlStateNormal];
            self.loadButton.backgroundColor = [UIColor systemBlueColor];
            break;
        case NativeFlowLateBinding:
            self.flowDescription.text = @"Late-Bind — Pre-load ad data headlessly, then bind to any custom view on demand. A two-step process.";
            [self.loadButton setTitle:@"Step 1: Pre-load" forState:UIControlStateNormal];
            self.loadButton.backgroundColor = [UIColor systemOrangeColor];
            break;
    }
}

#pragma mark - Flow Banner

- (void)updateFlowBannerWithText:(NSString *)text color:(UIColor *)color {
    self.flowBanner.text = text;
    self.flowBanner.textColor = color;
}

- (void)showBindButton:(BOOL)show {
    if (show && self.bindButton.hidden) {
        self.bindButton.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.bindButton.alpha = 1.0;
        }];
    } else if (!show && !self.bindButton.hidden) {
        [UIView animateWithDuration:0.2 animations:^{
            self.bindButton.alpha = 0;
        } completion:^(BOOL finished) {
            self.bindButton.hidden = YES;
        }];
    }
}

#pragma mark - Ad Unit

- (NSString *)adUnitId {
    NSString *adUnitId = [[CLXDemoConfigManager sharedManager] currentConfig].nativeAdUnitId;
    if (self.settings.nativeMediumAdUnitId.length > 0) {
        adUnitId = self.settings.nativeMediumAdUnitId;
    }
    return adUnitId;
}

- (CLXNativeAdLoader *)ensureLoader {
    if (!self.nativeAdLoader) {
        self.nativeAdLoader = [[CloudXCore shared] createNativeAdLoaderWithAdUnitIdentifier:[self adUnitId]];
        self.nativeAdLoader.nativeAdDelegate = self;
        self.nativeAdLoader.revenueDelegate = self;
        self.nativeAdLoader.placement = @"demo_native";
    }
    return self.nativeAdLoader;
}

#pragma mark - Load Action

- (void)loadAction {
    switch (self.activeFlow) {
        case NativeFlowTemplate:  [self loadTemplate]; break;
        case NativeFlowManual:    [self loadManual]; break;
        case NativeFlowLateBinding: [self loadLateBinding]; break;
    }
}

#pragma mark - Flow A: Template

- (void)loadNativeAd {
    [self loadTemplate];
}

- (void)loadTemplate {
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Native ad is already loading."];
        return;
    }
    [self resetAdState];
    self.receivedCallbacks = AdCallbackEventNone;
    self.activeFlow = NativeFlowTemplate;
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self updateFlowBannerWithText:@"Loading template..." color:[UIColor secondaryLabelColor]];
    [[self ensureLoader] loadAd];
}

#pragma mark - Flow B: Manual

- (void)loadManual {
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Native ad is already loading."];
        return;
    }
    [self resetAdState];
    self.receivedCallbacks = AdCallbackEventNone;
    self.activeFlow = NativeFlowManual;

    CLXNativeAdView *adView = [self buildManualAdView];
    CLXNativeAdViewBinder *binder = [[CLXNativeAdViewBinder alloc] initWithBuilderBlock:^(CLXNativeAdViewBinderBuilder *builder) {
        builder.titleLabelTag = CLXNativeAdViewTagTitleLabel;
        builder.bodyLabelTag = CLXNativeAdViewTagBodyLabel;
        builder.callToActionButtonTag = CLXNativeAdViewTagCallToActionButton;
        builder.iconImageViewTag = CLXNativeAdViewTagIconImageView;
        builder.mediaContentViewTag = CLXNativeAdViewTagMediaViewContainer;
        builder.advertiserLabelTag = CLXNativeAdViewTagAdvertiserLabel;
        builder.optionsContentViewTag = CLXNativeAdViewTagOptionsContentView;
    }];
    [adView bindViewsWithViewBinder:binder];

    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self updateFlowBannerWithText:@"Loading into custom publisher layout..." color:[UIColor secondaryLabelColor]];
    [[self ensureLoader] loadAdIntoAdView:adView];
}

#pragma mark - Flow C: Late-Binding (2-step)

- (void)loadLateBinding {
    if (self.isLoading) {
        [self showAlertWithTitle:@"Info" message:@"Native ad is already loading."];
        return;
    }
    [self resetAdState];
    self.receivedCallbacks = AdCallbackEventNone;
    self.activeFlow = NativeFlowLateBinding;
    self.isLoading = YES;
    [self updateStatusUIWithState:AdStateLoading];
    [self updateFlowBannerWithText:@"Step 1: Loading headlessly..." color:[UIColor secondaryLabelColor]];
    [[self ensureLoader] loadAd];
}

- (void)bindPreloadedAd {
    if (!self.preloadedAd) return;

    CLXNativeAdView *spotlightView = [self buildSpotlightAdView];
    CLXNativeAdViewBinder *binder = [[CLXNativeAdViewBinder alloc] initWithBuilderBlock:^(CLXNativeAdViewBinderBuilder *builder) {
        builder.titleLabelTag = CLXNativeAdViewTagTitleLabel;
        builder.bodyLabelTag = CLXNativeAdViewTagBodyLabel;
        builder.callToActionButtonTag = CLXNativeAdViewTagCallToActionButton;
        builder.iconImageViewTag = CLXNativeAdViewTagIconImageView;
        builder.mediaContentViewTag = CLXNativeAdViewTagMediaViewContainer;
        builder.advertiserLabelTag = CLXNativeAdViewTagAdvertiserLabel;
        builder.optionsContentViewTag = CLXNativeAdViewTagOptionsContentView;
    }];
    [spotlightView bindViewsWithViewBinder:binder];
    [[self ensureLoader] renderNativeAdView:spotlightView withAd:self.preloadedAd];
    [self displayAdView:spotlightView];

    self.preloadedAd = nil;
    [self showBindButton:NO];
    [self updateFlowBannerWithText:@"COMPLETE — Bound to custom view on demand" color:[UIColor systemGreenColor]];
    [[DemoAppLogger sharedInstance] logMessage:@"Flow C Step 2: Bound pre-loaded ad to spotlight view"];
}

#pragma mark - Destroy

- (void)destroyAd {
    [self resetAdState];
    [[DemoAppLogger sharedInstance] logMessage:@"Native ad destroyed"];
}

- (void)resetAdState {
    if (self.loadedAd) {
        [self.nativeAdLoader destroyAd:self.loadedAd];
        self.loadedAd = nil;
    }
    if (self.nativeAdView) {
        [self.nativeAdView removeFromSuperview];
        self.nativeAdView = nil;
    }
    if (self.nativeAdLoader) {
        [self.nativeAdLoader destroy];
        self.nativeAdLoader = nil;
    }
    self.preloadedAd = nil;
    self.isLoading = NO;
    [self showBindButton:NO];
    [self updateStatusUIWithState:AdStateNoAd];
    self.flowBanner.text = nil;
}

#pragma mark - Manual Ad View Builder (media-hero layout)

- (CLXNativeAdView *)buildManualAdView {
    CLXNativeAdView *adView = [[CLXNativeAdView alloc] init];
    adView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0];
    adView.layer.cornerRadius = 16;
    adView.clipsToBounds = YES;

    UIView *media = [[UIView alloc] init];
    media.tag = CLXNativeAdViewTagMediaViewContainer;
    media.clipsToBounds = YES;
    media.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:media];

    UIView *gradient = [[UIView alloc] init];
    gradient.translatesAutoresizingMaskIntoConstraints = NO;
    gradient.userInteractionEnabled = NO;
    [adView addSubview:gradient];

    UIView *options = [[UIView alloc] init];
    options.tag = CLXNativeAdViewTagOptionsContentView;
    options.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:options];

    UIView *bottomBar = [[UIView alloc] init];
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:bottomBar];

    UIImageView *icon = [[UIImageView alloc] init];
    icon.tag = CLXNativeAdViewTagIconImageView;
    icon.contentMode = UIViewContentModeScaleAspectFill;
    icon.clipsToBounds = YES;
    icon.layer.cornerRadius = 22;
    icon.layer.borderWidth = 2;
    icon.layer.borderColor = [UIColor whiteColor].CGColor;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBar addSubview:icon];

    UILabel *title = [[UILabel alloc] init];
    title.tag = CLXNativeAdViewTagTitleLabel;
    title.font = [UIFont boldSystemFontOfSize:15];
    title.textColor = [UIColor whiteColor];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBar addSubview:title];

    UILabel *advertiser = [[UILabel alloc] init];
    advertiser.tag = CLXNativeAdViewTagAdvertiserLabel;
    advertiser.font = [UIFont systemFontOfSize:10];
    advertiser.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    advertiser.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBar addSubview:advertiser];

    UILabel *body = [[UILabel alloc] init];
    body.tag = CLXNativeAdViewTagBodyLabel;
    body.font = [UIFont systemFontOfSize:12];
    body.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    body.numberOfLines = 1;
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBar addSubview:body];

    UIButton *cta = [UIButton buttonWithType:UIButtonTypeSystem];
    cta.tag = CLXNativeAdViewTagCallToActionButton;
    cta.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    cta.backgroundColor = [UIColor systemGreenColor];
    [cta setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cta.layer.cornerRadius = 16;
    cta.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
    cta.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBar addSubview:cta];

    [NSLayoutConstraint activateConstraints:@[
        [media.topAnchor constraintEqualToAnchor:adView.topAnchor],
        [media.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor],
        [media.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor],
        [media.heightAnchor constraintEqualToConstant:300],

        [gradient.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor],
        [gradient.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor],
        [gradient.bottomAnchor constraintEqualToAnchor:media.bottomAnchor],
        [gradient.heightAnchor constraintEqualToConstant:80],

        [options.topAnchor constraintEqualToAnchor:adView.topAnchor constant:8],
        [options.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor constant:-8],
        [options.widthAnchor constraintEqualToConstant:28],
        [options.heightAnchor constraintEqualToConstant:28],

        [bottomBar.topAnchor constraintEqualToAnchor:media.bottomAnchor constant:10],
        [bottomBar.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor constant:12],
        [bottomBar.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor constant:-12],
        [bottomBar.bottomAnchor constraintEqualToAnchor:adView.bottomAnchor constant:-12],

        [icon.topAnchor constraintEqualToAnchor:bottomBar.topAnchor],
        [icon.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor],
        [icon.widthAnchor constraintEqualToConstant:44],
        [icon.heightAnchor constraintEqualToConstant:44],

        [title.topAnchor constraintEqualToAnchor:bottomBar.topAnchor],
        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:10],
        [title.trailingAnchor constraintEqualToAnchor:cta.leadingAnchor constant:-8],

        [advertiser.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:1],
        [advertiser.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [body.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:8],
        [body.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor],
        [body.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor],
        [body.bottomAnchor constraintEqualToAnchor:bottomBar.bottomAnchor],

        [cta.centerYAnchor constraintEqualToAnchor:icon.centerYAnchor],
        [cta.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor],
        [cta.heightAnchor constraintEqualToConstant:32],
    ]];

    dispatch_async(dispatch_get_main_queue(), ^{
        CAGradientLayer *grad = [CAGradientLayer layer];
        grad.colors = @[(id)[UIColor clearColor].CGColor,
                        (id)[UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.9].CGColor];
        grad.frame = gradient.bounds;
        [gradient.layer insertSublayer:grad atIndex:0];

        [gradient addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
    });

    return adView;
}

#pragma mark - Spotlight Ad View Builder (light card for Flow C)

- (CLXNativeAdView *)buildSpotlightAdView {
    CLXNativeAdView *adView = [[CLXNativeAdView alloc] init];
    adView.backgroundColor = [UIColor colorWithRed:1.0 green:0.97 blue:0.93 alpha:1.0];
    adView.layer.cornerRadius = 16;
    adView.clipsToBounds = YES;

    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:header];

    UIImageView *icon = [[UIImageView alloc] init];
    icon.tag = CLXNativeAdViewTagIconImageView;
    icon.contentMode = UIViewContentModeScaleAspectFill;
    icon.clipsToBounds = YES;
    icon.layer.cornerRadius = 8;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:icon];

    UIView *options = [[UIView alloc] init];
    options.tag = CLXNativeAdViewTagOptionsContentView;
    options.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:options];

    UILabel *title = [[UILabel alloc] init];
    title.tag = CLXNativeAdViewTagTitleLabel;
    title.font = [UIFont boldSystemFontOfSize:16];
    title.textColor = [UIColor colorWithRed:0.2 green:0.1 blue:0.0 alpha:1.0];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:title];

    UILabel *advertiser = [[UILabel alloc] init];
    advertiser.tag = CLXNativeAdViewTagAdvertiserLabel;
    advertiser.font = [UIFont systemFontOfSize:11];
    advertiser.textColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:1.0];
    advertiser.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:advertiser];

    UILabel *body = [[UILabel alloc] init];
    body.tag = CLXNativeAdViewTagBodyLabel;
    body.font = [UIFont systemFontOfSize:13];
    body.textColor = [UIColor colorWithRed:0.35 green:0.25 blue:0.15 alpha:1.0];
    body.numberOfLines = 2;
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:body];

    UIView *media = [[UIView alloc] init];
    media.tag = CLXNativeAdViewTagMediaViewContainer;
    media.clipsToBounds = YES;
    media.layer.cornerRadius = 12;
    media.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:media];

    UIButton *cta = [UIButton buttonWithType:UIButtonTypeSystem];
    cta.tag = CLXNativeAdViewTagCallToActionButton;
    cta.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    cta.backgroundColor = [UIColor systemOrangeColor];
    [cta setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cta.layer.cornerRadius = 22;
    cta.translatesAutoresizingMaskIntoConstraints = NO;
    [adView addSubview:cta];

    CGFloat pad = 14;
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:adView.topAnchor constant:pad],
        [header.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor constant:pad],
        [header.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor constant:-pad],

        [icon.topAnchor constraintEqualToAnchor:header.topAnchor],
        [icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [icon.widthAnchor constraintEqualToConstant:44],
        [icon.heightAnchor constraintEqualToConstant:44],
        [icon.bottomAnchor constraintEqualToAnchor:header.bottomAnchor],

        [title.topAnchor constraintEqualToAnchor:header.topAnchor constant:2],
        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:10],
        [title.trailingAnchor constraintEqualToAnchor:options.leadingAnchor constant:-8],

        [advertiser.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:1],
        [advertiser.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],

        [options.topAnchor constraintEqualToAnchor:header.topAnchor],
        [options.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [options.widthAnchor constraintEqualToConstant:28],
        [options.heightAnchor constraintEqualToConstant:28],

        [body.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8],
        [body.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor constant:pad],
        [body.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor constant:-pad],

        [media.topAnchor constraintEqualToAnchor:body.bottomAnchor constant:10],
        [media.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor constant:pad],
        [media.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor constant:-pad],
        [media.heightAnchor constraintEqualToConstant:280],

        [cta.topAnchor constraintEqualToAnchor:media.bottomAnchor constant:12],
        [cta.leadingAnchor constraintEqualToAnchor:adView.leadingAnchor constant:pad],
        [cta.trailingAnchor constraintEqualToAnchor:adView.trailingAnchor constant:-pad],
        [cta.heightAnchor constraintEqualToConstant:44],
        [cta.bottomAnchor constraintEqualToAnchor:adView.bottomAnchor constant:-pad],
    ]];

    return adView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        UIView *gradient = object;
        for (CALayer *layer in gradient.layer.sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                layer.frame = gradient.bounds;
            }
        }
    }
}

#pragma mark - Display

- (void)displayAdView:(CLXNativeAdView *)adView {
    [self.nativeAdView removeFromSuperview];
    self.nativeAdView = adView;
    adView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.adContainerView addSubview:adView];

    [NSLayoutConstraint activateConstraints:@[
        [adView.topAnchor constraintEqualToAnchor:self.adContainerView.topAnchor],
        [adView.leadingAnchor constraintEqualToAnchor:self.adContainerView.leadingAnchor],
        [adView.trailingAnchor constraintEqualToAnchor:self.adContainerView.trailingAnchor],
        [adView.bottomAnchor constraintEqualToAnchor:self.adContainerView.bottomAnchor]
    ]];
}

#pragma mark - CLXNativeAdDelegate

- (void)didLoadNativeAd:(nullable CLXNativeAdView *)nativeAdView forAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"✅ Native didLoadNativeAd" ad:ad];
    self.isLoading = NO;
    self.receivedCallbacks |= AdCallbackEventLoaded;
    self.loadedAd = ad;

    if (self.activeFlow == NativeFlowLateBinding) {
        self.preloadedAd = ad;
        [self updateStatusUIWithState:AdStateReady];
        [self updateFlowBannerWithText:@"Step 1 done — tap 'Bind & Display'" color:[UIColor systemOrangeColor]];
        [self showBindButton:YES];
        [[DemoAppLogger sharedInstance] logMessage:@"Flow C Step 1: Ad pre-loaded — waiting for bind"];
        return;
    }

    [self updateStatusUIWithState:AdStateReady];

    if (nativeAdView) {
        [self displayAdView:nativeAdView];
        [self updateFlowBannerWithText:@"MANUAL — Custom publisher layout" color:[UIColor systemBlueColor]];
    } else {
        CLXNativeAdView *templateView = [CLXNativeAdView viewFromAd:ad.nativeAd];
        [[self ensureLoader] renderNativeAdView:templateView withAd:ad];
        [self displayAdView:templateView];
        [self updateFlowBannerWithText:@"TEMPLATE — SDK auto-generated view" color:[UIColor systemGreenColor]];
    }
}

- (void)didFailToLoadNativeAdForAdUnitIdentifier:(NSString *)adUnitId error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"❌ Native failed (%@) - %@", adUnitId, error.localizedDescription]];
    self.isLoading = NO;
    [self updateStatusUIWithState:AdStateNoAd];
    self.flowBanner.text = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = error ? [error detailedDemoDescription] : @"Unknown error";
        [self showAlertWithTitle:@"Native Load Failed" message:msg];
    });
}

- (void)didClickNativeAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventClicked;
    [[DemoAppLogger sharedInstance] logAdEvent:@"👆 Native didClickNativeAd" ad:ad];
}

- (void)didExpireNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"⏰ Native didExpireNativeAd" ad:ad];
    [self resetAdState];
}

- (void)didCloseNativeAd:(CLXAd *)ad {
    [[DemoAppLogger sharedInstance] logAdEvent:@"🚪 Native didCloseNativeAd — user reported/hid ad via AdChoices" ad:ad];
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    self.receivedCallbacks |= AdCallbackEventRevenueReceived;
    [[DemoAppLogger sharedInstance] logAdEvent:@"💰 Native didPayRevenueForAd" ad:ad];
}

- (nullable UIView *)adViewForClickTesting {
    return self.nativeAdView;
}

- (void)updateStatusUIWithState:(AdState)state {
    self.adState = state;
    [super updateStatusUIWithState:state];
}

@end
