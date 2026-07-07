#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (NSString *)sdkVersion;
+ (nullable NSString *)placementIDForAdUnitID:(NSString *)adUnitID;

@end

NS_ASSUME_NONNULL_END
