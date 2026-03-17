#import "CLXVungleMetadataProvider.h"
#import "CLXVungleAdapterVersion.h"
#import "CLXVungleInitializer.h"

@implementation CLXVungleMetadataProvider

+ (instancetype)createInstance {
    return [[CLXVungleMetadataProvider alloc] init];
}

- (NSString *)adapterVersion {
    return CLXVungleAdapterVersion;
}

- (NSString *)networkSdkVersion {
    return [CLXVungleInitializer sdkVersion];
}

@end
