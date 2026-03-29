#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @brief Non-blocking dropdown toast for surfacing errors and informational messages.
 @discussion Slides down from the top of the screen, auto-dismisses after a few seconds.
             Tapping the toast presents a detail popup with the full message.
             Supports queueing — multiple toasts display sequentially without overlap.
 */
@interface DemoToastView : UIView

/**
 @brief Shows a dropdown toast at the top of the given view controller's view.
 @param viewController The view controller whose view will host the toast.
 @param title Bold title text displayed on the toast.
 @param message Brief description displayed below the title (truncated to 2 lines).
 */
+ (void)showInViewController:(UIViewController *)viewController
                       title:(NSString *)title
                     message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
