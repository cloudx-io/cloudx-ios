//
//  CLXUnityAdsInitializer.h
//  CloudXUnityAdsAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityAdsInitializer : CLXAdapterInitializer

@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;

+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
