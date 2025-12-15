#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (CLXIdentifier)

/// Returns the device hardware identifier (e.g., "iPhone17,1", "iPad14,1").
/// On simulator returns architecture (e.g., "arm64", "x86_64").
@property (nonatomic, class, readonly) NSString *clx_deviceIdentifier;

/// Returns the device type string (e.g., "iPhone", "iPad", "Simulator").
@property (nonatomic, class, readonly) NSString *clx_deviceType;

/// Returns the device generation string (e.g., "16 Pro", "14 Pro Max").
@property (nonatomic, class, readonly) NSString *clx_deviceGeneration;

/// Returns the device pixels per inch.
@property (nonatomic, class, readonly) NSInteger clx_ppi;

@end

NS_ASSUME_NONNULL_END
