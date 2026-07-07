#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXUtils : NSObject

+ (NSString *)channel;
+ (nullable NSString *)resolvePlacementIDFromExtras:(NSDictionary<NSString *, id> *)extras;
+ (nullable NSString *)resolvePayloadFromExtras:(NSDictionary<NSString *, id> *)extras
                                            adm:(NSString *)adm;

@end

NS_ASSUME_NONNULL_END
