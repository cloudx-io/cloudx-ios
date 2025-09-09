#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (Identifier)

@property (nonatomic, class, readonly) NSString *deviceIdentifier;
@property (nonatomic, class, readonly) NSString *deviceType;
@property (nonatomic, class, readonly) NSString *deviceGeneration;
@property (nonatomic, class, readonly) NSInteger ppi;

+ (NSDictionary<NSString *, id> *)mapToDeviceWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END 