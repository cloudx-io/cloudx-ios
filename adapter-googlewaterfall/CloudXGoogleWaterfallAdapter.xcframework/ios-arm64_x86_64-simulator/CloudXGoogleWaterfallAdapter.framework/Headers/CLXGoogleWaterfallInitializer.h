#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
