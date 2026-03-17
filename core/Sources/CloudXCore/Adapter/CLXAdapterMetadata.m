#import <CloudXCore/CLXAdapterMetadata.h>

@implementation CLXAdapterMetadata

- (instancetype)initWithNetwork:(NSString *)network
                 adapterVersion:(NSString *)adapterVersion
              networkSdkVersion:(NSString *)networkSdkVersion {
    self = [super init];
    if (self) {
        _network = [network copy];
        _adapterVersion = [adapterVersion copy];
        _networkSdkVersion = [networkSdkVersion copy];
    }
    return self;
}

- (NSDictionary *)json {
    return @{
        @"network": self.network ?: @"",
        @"adapterVersion": self.adapterVersion ?: @"",
        @"networkSdkVersion": self.networkSdkVersion ?: @""
    };
}

@end
