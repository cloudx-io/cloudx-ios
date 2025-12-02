/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDebugButton.h"

static NSString *const kCLXDebugButtonPositionXKey = @"io.cloudx.debug.button.position.x";
static NSString *const kCLXDebugButtonPositionYKey = @"io.cloudx.debug.button.position.y";
static const CGFloat kButtonSize = 50.0;

@interface CLXDebugButton ()
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) BOOL isFlashing;
@property (nonatomic, strong) UIColor *normalBackgroundColor;
@end

@implementation CLXDebugButton

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, kButtonSize, kButtonSize)];
    if (self) {
        [self setupAppearance];
        [self setupGestures];
    }
    return self;
}

- (void)setupAppearance {
    // Circular button
    self.layer.cornerRadius = kButtonSize / 2.0;
    
    // Pastel purple background (slightly darker)
    self.normalBackgroundColor = [UIColor colorWithRed:0.55 green:0.35 blue:0.75 alpha:1.0];
    self.backgroundColor = self.normalBackgroundColor;
    
    // White border
    self.layer.borderWidth = 3.0;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    
    // Light purple glow shadow (visible on both light and dark backgrounds)
    // Using a soft lavender purple that contrasts with white backgrounds
    self.layer.shadowColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.9 alpha:1.0].CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 12.0;
    self.layer.shadowOpacity = 0.9;
    self.clipsToBounds = NO;
    
    // Bug icon or "D" text
    if (@available(iOS 13.0, *)) {
        UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium];
        UIImage *bugImage = [UIImage systemImageNamed:@"ladybug.fill" withConfiguration:config];
        if (!bugImage) {
            // Fallback if ladybug not available
            bugImage = [UIImage systemImageNamed:@"ant.fill" withConfiguration:config];
        }
        [self setImage:bugImage forState:UIControlStateNormal];
        // White icon
        self.tintColor = [UIColor whiteColor];
    } else {
        [self setTitle:@"D" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    }
}

- (void)setupGestures {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.panGesture];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *superview = self.superview;
    if (!superview) return;
    
    CGPoint translation = [gesture translationInView:superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    // Keep within bounds
    CGFloat halfWidth = self.bounds.size.width / 2.0;
    CGFloat halfHeight = self.bounds.size.height / 2.0;
    CGFloat safeAreaTop = 50.0; // Approximate safe area
    CGFloat safeAreaBottom = 34.0;
    
    newCenter.x = MAX(halfWidth, MIN(superview.bounds.size.width - halfWidth, newCenter.x));
    newCenter.y = MAX(safeAreaTop + halfHeight, MIN(superview.bounds.size.height - safeAreaBottom - halfHeight, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:superview];
    
    // Notify position change
    if (self.onPositionChange) {
        self.onPositionChange(newCenter);
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self savePosition];
    }
}

- (void)flashError {
    if (self.isFlashing) return;
    self.isFlashing = YES;
    
    UIColor *errorColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:0.95];
    UIColor *errorBorderColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundColor = errorColor;
        self.layer.borderColor = errorBorderColor.CGColor;
        self.transform = CGAffineTransformMakeScale(1.15, 1.15);
    } completion:^(BOOL finished) {
        // Hold for 2 seconds, then fade back
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                self.backgroundColor = self.normalBackgroundColor;
                self.layer.borderColor = [UIColor whiteColor].CGColor;
                self.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.isFlashing = NO;
            }];
        });
    }];
}

- (void)savePosition {
    [[NSUserDefaults standardUserDefaults] setFloat:self.center.x forKey:kCLXDebugButtonPositionXKey];
    [[NSUserDefaults standardUserDefaults] setFloat:self.center.y forKey:kCLXDebugButtonPositionYKey];
}

- (void)restorePosition {
    CGFloat x = [[NSUserDefaults standardUserDefaults] floatForKey:kCLXDebugButtonPositionXKey];
    CGFloat y = [[NSUserDefaults standardUserDefaults] floatForKey:kCLXDebugButtonPositionYKey];
    
    if (x > 0 && y > 0) {
        self.center = CGPointMake(x, y);
    }
}

@end

