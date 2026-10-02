#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A read-only log that shows every DemoAppLogger line as it is written, so an ad flow screen
 * shows what its ad code reports. Keeps the last 500 lines, the same bound as DemoAppLogger, so a
 * screen left open through a retry loop cannot grow without limit.
 */
@interface LiveLogTextView : UITextView

- (instancetype)initWithAccessibilityLabel:(NSString *)accessibilityLabel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame textContainer:(nullable NSTextContainer *)textContainer NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
