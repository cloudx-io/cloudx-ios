#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/** The layout the ad flow screens share: status lines, a live log that fills the middle and a Show button. */
@interface DemoFlowLayout : NSObject

+ (UILabel *)makeStatusLabel;

/** The button starts disabled; the screen enables it once its ad controller exists. */
+ (UIButton *)makeShowButton;

/** Stacks `views` top to bottom inside the safe area of `view`, 12 points from each edge. */
+ (void)installViews:(NSArray<UIView *> *)views inView:(UIView *)view;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
