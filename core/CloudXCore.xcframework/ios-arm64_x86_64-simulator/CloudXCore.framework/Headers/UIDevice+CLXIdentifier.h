#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (Identifier)

/// Returns the device hardware identifier (e.g., "iPhone17,1", "iPad14,1").
/// On simulator returns architecture (e.g., "arm64", "x86_64").
@property (nonatomic, class, readonly) NSString *deviceIdentifier;

@end

NS_ASSUME_NONNULL_END
