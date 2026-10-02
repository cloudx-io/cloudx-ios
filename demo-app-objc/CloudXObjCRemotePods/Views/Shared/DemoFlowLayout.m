#import "DemoFlowLayout.h"

@implementation DemoFlowLayout

+ (UILabel *)makeStatusLabel {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15];
    label.numberOfLines = 0;
    return label;
}

+ (UIButton *)makeShowButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Show Interstitial" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.enabled = NO;
    [button.heightAnchor constraintEqualToConstant:44].active = YES;
    return button;
}

+ (void)installViews:(NSArray<UIView *> *)views inView:(UIView *)view {
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:views];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:stack];

    UILayoutGuide *safeArea = view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:12],
        [stack.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-12],
        [stack.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-12]
    ]];
}

@end
