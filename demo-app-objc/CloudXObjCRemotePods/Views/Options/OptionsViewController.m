#import "OptionsViewController.h"
#import "AdDemoTabViewController.h"
#import "DemoAppLogger.h"
#import "FirstLookViewController.h"

static UIColor *ColorFromHex(NSUInteger hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1];
}

@implementation OptionsViewController

+ (AdDemoTabViewController *)openGeneralInWindow:(UIWindow *)window {
    AdDemoTabViewController *tabViewController = [[AdDemoTabViewController alloc] init];
    [self replaceRootOfWindow:window withViewController:tabViewController];
    return tabViewController;
}

+ (void)openFirstLookInWindow:(UIWindow *)window {
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:[[FirstLookViewController alloc] init]];
    [self replaceRootOfWindow:window withViewController:navigationController];
}

+ (void)replaceRootOfWindow:(UIWindow *)window withViewController:(UIViewController *)viewController {
    [viewController loadViewIfNeeded];
    [UIView transitionWithView:window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        window.rootViewController = viewController;
    }
                    completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ColorFromHex(0x345AB5);

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"CloudX";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:32];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    UIButton *generalButton = [self makeButtonWithTitle:@"General" enabled:YES];
    [generalButton addTarget:self action:@selector(generalTapped) forControlEvents:UIControlEventTouchUpInside];
    UIButton *firstLookButton = [self makeButtonWithTitle:@"First Look" enabled:YES];
    [firstLookButton addTarget:self action:@selector(firstLookTapped) forControlEvents:UIControlEventTouchUpInside];
    UIButton *arbiterButton = [self makeButtonWithTitle:@"Arbiter/TPA" enabled:NO];

    UIStackView *buttonStack = [[UIStackView alloc] initWithArrangedSubviews:@[generalButton, firstLookButton, arbiterButton]];
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.spacing = 16;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, buttonStack]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 48;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    // Fill up to 280 points, but always keep 24 points of side margin on narrow screens.
    NSLayoutConstraint *preferredWidth = [stack.widthAnchor constraintEqualToConstant:280];
    preferredWidth.priority = UILayoutPriorityDefaultHigh;
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        preferredWidth,
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:24],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-24]
    ]];
}

- (void)generalTapped {
    UIWindow *window = self.view.window;
    if (!window) {
        return;
    }
    [[DemoAppLogger sharedInstance] logMessage:@"Opening the General demo"];
    [OptionsViewController openGeneralInWindow:window];
}

- (void)firstLookTapped {
    UIWindow *window = self.view.window;
    if (!window) {
        return;
    }
    [[DemoAppLogger sharedInstance] logMessage:@"Opening the First Look demo"];
    [OptionsViewController openFirstLookInWindow:window];
}

- (UIButton *)makeButtonWithTitle:(NSString *)title enabled:(BOOL)enabled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:ColorFromHex(0x323232) forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.backgroundColor = ColorFromHex(0xF6F6F6);
    button.layer.cornerRadius = 8;
    button.enabled = enabled;
    button.alpha = enabled ? 1 : 0.5;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:60].active = YES;
    return button;
}

@end
