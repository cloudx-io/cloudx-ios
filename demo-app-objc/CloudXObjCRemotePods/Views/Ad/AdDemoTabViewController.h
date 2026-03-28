#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdDemoTabViewController : UITabBarController

/**
 * @brief Selects the tab at the given index, handling the "More" tab if needed.
 * @param index The zero-based tab index to select.
 */
- (void)selectTabIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END 