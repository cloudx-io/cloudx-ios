#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogsModalViewController : UIViewController

- (instancetype)initWithTitle:(NSString *)title;
- (void)refreshLogs;

@end

NS_ASSUME_NONNULL_END
