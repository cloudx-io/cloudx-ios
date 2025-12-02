/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDebugErrorView.h"
#import "CLXDebugOverlayManager.h"

@interface CLXDebugErrorView () {
    NSString *_storedTitle;
    NSString *_storedMessage;
    BOOL _didLayout;
}
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *viewLogsButton;
@end

@implementation CLXDebugErrorView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupWithTitle:title message:message];
    }
    return self;
}

+ (instancetype)errorViewWithFrame:(CGRect)frame title:(NSString *)title message:(NSString *)message {
    CLXDebugErrorView *view = [[CLXDebugErrorView alloc] initWithTitle:title message:message];
    view.frame = frame;
    return view;
}

- (void)setupWithTitle:(NSString *)title message:(NSString *)message {
    // Dark red-ish background
    self.backgroundColor = [UIColor colorWithRed:0.15 green:0.08 blue:0.08 alpha:0.95];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0].CGColor;
    self.clipsToBounds = YES;
    
    // Store title and message for layout
    _storedTitle = title;
    _storedMessage = message;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Only setup once we have a valid frame
    if (self.bounds.size.width > 0 && self.bounds.size.height > 0 && !_didLayout) {
        _didLayout = YES;
        [self setupLayoutWithTitle:_storedTitle message:_storedMessage];
    }
}

- (void)setupLayoutWithTitle:(NSString *)title message:(NSString *)message {
    // Determine if this is a banner (wide) or MREC (more square)
    CGFloat aspectRatio = self.bounds.size.width / self.bounds.size.height;
    BOOL isBanner = aspectRatio > 3.0;  // Banners are typically 6:1 or wider
    
    if (isBanner) {
        [self setupBannerLayoutWithTitle:title message:message];
    } else {
        [self setupMRECLayoutWithTitle:title message:message];
    }
}

- (void)setupBannerLayoutWithTitle:(NSString *)title message:(NSString *)message {
    // Horizontal layout for banners
    UIStackView *mainStack = [[UIStackView alloc] init];
    mainStack.axis = UILayoutConstraintAxisHorizontal;
    mainStack.alignment = UIStackViewAlignmentCenter;
    mainStack.spacing = 8;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:mainStack];
    
    // Left side: Title + message combined
    self.messageLabel = [[UILabel alloc] init];
    NSString *errorText = [NSString stringWithFormat:@"❌ %@: %@", title, message ?: @"Unknown error"];
    self.messageLabel.text = errorText;
    self.messageLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.messageLabel.textColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
    self.messageLabel.textAlignment = NSTextAlignmentLeft;
    self.messageLabel.numberOfLines = 2;
    self.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.messageLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [mainStack addArrangedSubview:self.messageLabel];
    
    // Right side: View Logs button
    self.viewLogsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.viewLogsButton setTitle:@"View Logs" forState:UIControlStateNormal];
    [self.viewLogsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.viewLogsButton.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [self.viewLogsButton addTarget:self action:@selector(viewLogsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.viewLogsButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.viewLogsButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [mainStack addArrangedSubview:self.viewLogsButton];
    
    // Fill the container with padding
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-6],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10]
    ]];
}

- (void)setupMRECLayoutWithTitle:(NSString *)title message:(NSString *)message {
    // Vertical centered layout for MRECs
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stack];
    
    // Title with error icon
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = [NSString stringWithFormat:@"❌ %@", title];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:self.titleLabel];
    
    // Error message
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.text = [NSString stringWithFormat:@"\"%@\"", message ?: @"Unknown error"];
    self.messageLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.messageLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 3;
    [stack addArrangedSubview:self.messageLabel];
    
    // View Logs button
    self.viewLogsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.viewLogsButton setTitle:@"View Logs" forState:UIControlStateNormal];
    [self.viewLogsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.viewLogsButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.viewLogsButton addTarget:self action:@selector(viewLogsTapped) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:self.viewLogsButton];
    
    // Center the stack
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:16],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-16]
    ]];
}

- (void)viewLogsTapped {
    // Find the top view controller and present the debug log viewer
    UIViewController *topVC = [self topViewController];
    if (!topVC) return;
    
    // Import dynamically to avoid circular dependency
    Class debugVCClass = NSClassFromString(@"CLXDebugLogViewController");
    if (debugVCClass) {
        UIViewController *debugVC = [[debugVCClass alloc] init];
        debugVC.modalPresentationStyle = UIModalPresentationPageSheet;
        
        if (@available(iOS 15.0, *)) {
            if (debugVC.sheetPresentationController) {
                debugVC.sheetPresentationController.detents = @[[UISheetPresentationControllerDetent largeDetent]];
                debugVC.sheetPresentationController.prefersGrabberVisible = YES;
            }
        }
        
        [topVC presentViewController:debugVC animated:YES completion:nil];
    }
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = [self findKeyWindow];
    UIViewController *rootVC = keyWindow.rootViewController;
    return [self topViewControllerFrom:rootVC];
}

- (UIWindow *)findKeyWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
}

- (UIViewController *)topViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerFrom:((UINavigationController *)vc).visibleViewController];
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerFrom:((UITabBarController *)vc).selectedViewController];
    }
    if (vc.presentedViewController) {
        return [self topViewControllerFrom:vc.presentedViewController];
    }
    return vc;
}

@end

