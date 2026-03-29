#import "DemoToastView.h"

static const NSTimeInterval kToastDisplayDuration = 4.0;
static const NSTimeInterval kToastAnimationDuration = 0.3;
static const CGFloat kToastHorizontalPadding = 16.0;
static const CGFloat kToastInternalPadding = 12.0;
static const CGFloat kToastCornerRadius = 12.0;

@interface DemoToastView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, copy) NSString *fullMessage;
@property (nonatomic, weak) UIViewController *hostViewController;
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;

@end

static NSMutableArray<void (^)(void)> *_toastQueue;
static BOOL _isShowingToast = NO;
static BOOL _isDismissing = NO;

@implementation DemoToastView

+ (void)initialize {
    if (self == [DemoToastView class]) {
        _toastQueue = [NSMutableArray new];
    }
}

+ (void)showInViewController:(UIViewController *)viewController
                       title:(NSString *)title
                     message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        void (^showBlock)(void) = ^{
            _isShowingToast = YES;
            [self presentToastInViewController:viewController title:title message:message];
        };

        if (_isShowingToast) {
            [_toastQueue addObject:showBlock];
        } else {
            showBlock();
        }
    });
}

+ (void)presentToastInViewController:(UIViewController *)viewController
                               title:(NSString *)title
                             message:(NSString *)message {
    DemoToastView *toast = [[DemoToastView alloc] initWithTitle:title
                                                        message:message
                                             hostViewController:viewController];
    [viewController.view addSubview:toast];

    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.topConstraint = [toast.topAnchor constraintEqualToAnchor:viewController.view.safeAreaLayoutGuide.topAnchor
                                                           constant:-120];

    [NSLayoutConstraint activateConstraints:@[
        toast.topConstraint,
        [toast.leadingAnchor constraintEqualToAnchor:viewController.view.leadingAnchor constant:kToastHorizontalPadding],
        [toast.trailingAnchor constraintEqualToAnchor:viewController.view.trailingAnchor constant:-kToastHorizontalPadding]
    ]];

    [viewController.view layoutIfNeeded];

    toast.topConstraint.constant = 8;
    [UIView animateWithDuration:kToastAnimationDuration
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        [viewController.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [toast scheduleAutoDismiss];
    }];
}

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
           hostViewController:(UIViewController *)hostVC {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _fullMessage = message ?: @"";
        _hostViewController = hostVC;
        [self setupWithTitle:title ?: @"" message:_fullMessage];
    }
    return self;
}

- (void)setupWithTitle:(NSString *)title message:(NSString *)message {
    self.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.18 alpha:0.95];
    self.layer.cornerRadius = kToastCornerRadius;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 8;
    self.layer.shadowOpacity = 0.3;
    self.clipsToBounds = NO;

    UIView *accentBar = [[UIView alloc] init];
    accentBar.backgroundColor = [UIColor systemOrangeColor];
    accentBar.layer.cornerRadius = 1.5;
    accentBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:accentBar];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.titleLabel];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.text = message;
    self.messageLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.messageLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    self.messageLabel.numberOfLines = 2;
    self.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.messageLabel];

    UILabel *tapHint = [[UILabel alloc] init];
    tapHint.text = @"Tap for details";
    tapHint.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    tapHint.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    tapHint.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:tapHint];

    [NSLayoutConstraint activateConstraints:@[
        [accentBar.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:kToastInternalPadding],
        [accentBar.topAnchor constraintEqualToAnchor:self.topAnchor constant:kToastInternalPadding],
        [accentBar.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-kToastInternalPadding],
        [accentBar.widthAnchor constraintEqualToConstant:3],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:accentBar.trailingAnchor constant:10],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:tapHint.leadingAnchor constant:-8],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:kToastInternalPadding],

        [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-kToastInternalPadding],
        [self.messageLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
        [self.messageLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-kToastInternalPadding],

        [tapHint.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-kToastInternalPadding],
        [tapHint.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toastTapped)];
    [self addGestureRecognizer:tap];

    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissAnimated)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:swipeUp];
}

- (void)scheduleAutoDismiss {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kToastDisplayDuration * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (self.superview && !_isDismissing) {
            [self dismissAnimated];
        }
    });
}

- (void)toastTapped {
    if (_isDismissing) return;

    UIViewController *host = self.hostViewController;
    NSString *msg = self.fullMessage;
    NSString *title = self.titleLabel.text;

    [self dismissAnimatedWithCompletion:^{
        if (!host) return;
        UIAlertController *detail = [UIAlertController alertControllerWithTitle:title
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [detail addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [host presentViewController:detail animated:YES completion:nil];
    }];
}

- (void)dismissAnimated {
    [self dismissAnimatedWithCompletion:nil];
}

- (void)dismissAnimatedWithCompletion:(void (^ _Nullable)(void))completion {
    if (_isDismissing) return;
    _isDismissing = YES;

    self.topConstraint.constant = -120;
    [UIView animateWithDuration:kToastAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        [self.superview layoutIfNeeded];
        self.alpha = 0;
    } completion:^(BOOL finished) {
        _isDismissing = NO;
        [self removeFromSuperview];
        if (completion) completion();
        [DemoToastView dequeueNext];
    }];
}

+ (void)dequeueNext {
    _isShowingToast = NO;
    if (_toastQueue.count > 0) {
        void (^next)(void) = _toastQueue.firstObject;
        [_toastQueue removeObjectAtIndex:0];
        next();
    }
}

@end
