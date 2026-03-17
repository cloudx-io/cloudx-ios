#import "CLXMetaMetadataProvider.h"
#import "CLXMetaAdapterVersion.h"
#import "CLXMetaInitializer.h"

@implementation CLXMetaMetadataProvider

+ (instancetype)createInstance {
    return [[CLXMetaMetadataProvider alloc] init];
}

- (NSString *)adapterVersion {
    return CLXMetaAdapterVersion;
}

- (NSString *)networkSdkVersion {
    return [CLXMetaInitializer sdkVersion];
}

@end
