#import "CLXUnityMetadataProvider.h"
#import "CLXUnityAdapterVersion.h"
#import "CLXUnityInitializer.h"

@implementation CLXUnityMetadataProvider

+ (instancetype)createInstance {
    return [[CLXUnityMetadataProvider alloc] init];
}

- (NSString *)adapterVersion {
    return CLXUnityAdapterVersion;
}

- (NSString *)networkSdkVersion {
    return [CLXUnityInitializer sdkVersion];
}

@end
