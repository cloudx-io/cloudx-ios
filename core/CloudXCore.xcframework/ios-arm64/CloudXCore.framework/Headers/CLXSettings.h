#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXSettings : NSObject

+ (instancetype)sharedInstance;

// MARK: - IFA Configuration

/// Retrieves the Identifier for Advertising (IFA) based on a priority system.
/// Priority: UserDefaults override > Real device IDFA > Placeholder (if no IDFA available)
- (NSString *)getIFA;

@end

NS_ASSUME_NONNULL_END
