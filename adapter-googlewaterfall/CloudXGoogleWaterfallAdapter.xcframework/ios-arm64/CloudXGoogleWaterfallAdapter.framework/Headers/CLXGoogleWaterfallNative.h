#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallNative : CLXAdapterNative

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras;

- (instancetype)initWithAdm:(NSString *)adm
                     extras:(nullable NSDictionary<NSString *, NSString *> *)extras
           fallbackGraceSec:(NSTimeInterval)fallbackGraceSec NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
