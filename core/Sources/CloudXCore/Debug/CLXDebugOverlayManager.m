/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDebugOverlayManager.h"
#import "CLXDebugButton.h"
#import "CLXDebugLogViewController.h"
#import "CLXUIApplicationProxy.h"
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CloudXCoreAPI.h>

@interface CLXDebugOverlayManager ()
@property (nonatomic, strong, nullable) CLXDebugButton *debugButton;
@property (nonatomic, strong, nullable) UILabel *statusLabel;
@property (nonatomic, strong, nullable) UIWindow *overlayWindow;
@end

@implementation CLXDebugOverlayManager

+ (instancetype)shared {
    static CLXDebugOverlayManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        // Listen for testMode changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTestModeChange:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isVisualDebuggingEnabled {
    // Visual debugging is completely separate from testMode
    return [CloudXCore isVisualDebuggingEnabled];
}

- (void)handleTestModeChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isVisualDebuggingEnabled]) {
            [self showIfEnabled];
        } else {
            [self hide];
        }
    });
}

- (BOOL)isVisible {
    return self.debugButton != nil && self.debugButton.superview != nil;
}

- (void)showIfEnabled {
    if (![self isVisualDebuggingEnabled]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupOverlay];
    });
}

- (void)setupOverlay {
    if (self.debugButton) {
        return; // Already set up
    }
    
    // Create the debug button
    self.debugButton = [[CLXDebugButton alloc] init];
    [self.debugButton addTarget:self action:@selector(debugButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Set up position change callback to move status label with button
    __weak typeof(self) weakSelf = self;
    self.debugButton.onPositionChange = ^(CGPoint center) {
        [weakSelf updateStatusLabelPosition];
    };
    
    // Find the key window and add the button
    UIWindow *keyWindow = [self findKeyWindow];
    if (keyWindow) {
        // Position in bottom-right by default
        CGFloat padding = 20.0;
        CGFloat safeAreaBottom = 34.0;
        if (@available(iOS 11.0, *)) {
            safeAreaBottom = keyWindow.safeAreaInsets.bottom;
        }
        
        self.debugButton.center = CGPointMake(
            keyWindow.bounds.size.width - padding - self.debugButton.bounds.size.width / 2.0,
            keyWindow.bounds.size.height - safeAreaBottom - padding - self.debugButton.bounds.size.height / 2.0
        );
        
        // Restore saved position if available
        [self.debugButton restorePosition];
        
        [keyWindow addSubview:self.debugButton];
        
        // Add status label next to button
        [self showStatusLabel:keyWindow];
        
        // Animate in
        self.debugButton.alpha = 0;
        self.debugButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            self.debugButton.alpha = 1.0;
            self.debugButton.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)showStatusLabel:(UIWindow *)window {
    // Remove any existing label
    [self.statusLabel removeFromSuperview];
    
    // Create status label (two lines)
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"visual debugging\nenabled";
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.statusLabel.layer.cornerRadius = 6;
    self.statusLabel.clipsToBounds = YES;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    
    // Size for multiline text
    CGSize maxSize = CGSizeMake(200, CGFLOAT_MAX);
    CGSize textSize = [self.statusLabel.text boundingRectWithSize:maxSize
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName: self.statusLabel.font}
                                                          context:nil].size;
    self.statusLabel.frame = CGRectMake(0, 0, ceil(textSize.width) + 16, ceil(textSize.height) + 8);
    
    // Position to the left of the button (reduced padding)
    [self updateStatusLabelPosition];
    
    [window addSubview:self.statusLabel];
    
    // Animate in then fade out
    self.statusLabel.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.statusLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        // Fade out after 2 seconds
        [UIView animateWithDuration:0.5 delay:2.0 options:0 animations:^{
            self.statusLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [self.statusLabel removeFromSuperview];
            self.statusLabel = nil;
        }];
    }];
}

- (void)updateStatusLabelPosition {
    if (!self.statusLabel || !self.debugButton) return;
    
    // Position to the left of the button with minimal gap (4pt)
    CGFloat buttonCenterX = self.debugButton.center.x;
    CGFloat buttonCenterY = self.debugButton.center.y;
    CGFloat labelRightEdge = buttonCenterX - self.debugButton.bounds.size.width / 2.0 - 4;
    self.statusLabel.center = CGPointMake(labelRightEdge - self.statusLabel.bounds.size.width / 2.0, buttonCenterY);
}

- (UIWindow *)findKeyWindow {
    return [CLXUIApplicationProxy keyWindow];
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.debugButton) {
            [UIView animateWithDuration:0.2 animations:^{
                self.debugButton.alpha = 0;
                self.debugButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
            } completion:^(BOOL finished) {
                [self.debugButton removeFromSuperview];
                self.debugButton = nil;
            }];
        }
    });
}

- (void)flashError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.debugButton flashError];
    });
}

- (void)debugButtonTapped {
    UIViewController *topVC = [self topViewController];
    if (!topVC) return;
    
    CLXDebugLogViewController *debugVC = [[CLXDebugLogViewController alloc] init];
    debugVC.modalPresentationStyle = UIModalPresentationPageSheet;
    
    if (@available(iOS 15.0, *)) {
        if (debugVC.sheetPresentationController) {
            debugVC.sheetPresentationController.detents = @[[UISheetPresentationControllerDetent largeDetent]];
            debugVC.sheetPresentationController.prefersGrabberVisible = YES;
        }
    }
    
    [topVC presentViewController:debugVC animated:YES completion:nil];
}

- (UIViewController *)topViewController {
    UIWindow *keyWindow = [self findKeyWindow];
    UIViewController *rootVC = keyWindow.rootViewController;
    return [self topViewControllerFrom:rootVC];
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

