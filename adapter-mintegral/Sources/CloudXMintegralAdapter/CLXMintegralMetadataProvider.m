#import "CLXMintegralMetadataProvider.h"
#import "CLXMintegralAdapterVersion.h"
#import "CLXMintegralInitializer.h"

@implementation CLXMintegralMetadataProvider

+ (instancetype)createInstance {
    return [[CLXMintegralMetadataProvider alloc] init];
}

- (NSString *)adapterVersion {
    return CLXMintegralAdapterVersion;
}

- (NSString *)networkSdkVersion {
    return [CLXMintegralInitializer sdkVersion];
}

@end
