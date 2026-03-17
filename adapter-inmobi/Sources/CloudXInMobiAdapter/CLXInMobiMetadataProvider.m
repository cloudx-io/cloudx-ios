#import "CLXInMobiMetadataProvider.h"
#import "CLXInMobiAdapterVersion.h"
#import "CLXInMobiInitializer.h"

@implementation CLXInMobiMetadataProvider

+ (instancetype)createInstance {
    return [[CLXInMobiMetadataProvider alloc] init];
}

- (NSString *)adapterVersion {
    return CLXInMobiAdapterVersion;
}

- (NSString *)networkSdkVersion {
    return [CLXInMobiInitializer sdkVersion];
}

@end
