#import "CLXUnityAdsMetadataProvider.h"
#import "CLXUnityAdsAdapterVersion.h"
#import "CLXUnityAdsInitializer.h"

@implementation CLXUnityAdsMetadataProvider

+ (instancetype)createInstance {
    return [[CLXUnityAdsMetadataProvider alloc] init];
}

- (NSString *)adapterVersion {
    return CLXUnityAdsAdapterVersion;
}

- (NSString *)networkSdkVersion {
    return [CLXUnityAdsInitializer sdkVersion];
}

@end
