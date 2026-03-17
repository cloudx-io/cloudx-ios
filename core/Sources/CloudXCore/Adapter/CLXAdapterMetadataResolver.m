#import <CloudXCore/CLXAdapterMetadataResolver.h>
#import <CloudXCore/CLXAdNetwork.h>
#import <CloudXCore/CLXAdapterMetadata.h>
#import <CloudXCore/CLXAdapterMetadataProvider.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXAdapterMetadataResolver ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAdapterMetadataResolver

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"AdapterMetadataResolver"];
    }
    return self;
}

- (NSArray<CLXAdapterMetadata *> *)resolve {
    NSMutableArray<CLXAdapterMetadata *> *results = [NSMutableArray array];

    for (CLXAdNetwork networkName in CLXAllAdNetworks()) {
        NSString *className = CLXAdNetworkClassName(networkName);
        NSString *providerClassName = [NSString stringWithFormat:@"CLX%@MetadataProvider", className];
        NSString *namespace = CLXAdNetworkAdapterNamespace(networkName);
        Class providerClass = [self loadClassWithNamespace:namespace className:providerClassName];

        if (!providerClass) {
            continue;
        }

        if (![providerClass conformsToProtocol:@protocol(CLXAdapterMetadataProvider)]) {
            [self.logger warn:[NSString stringWithFormat:@"%@ does not conform to CLXAdapterMetadataProvider", providerClassName]];
            continue;
        }

        id<CLXAdapterMetadataProvider> provider = [providerClass createInstance];
        if (!provider) {
            [self.logger warn:[NSString stringWithFormat:@"Failed to create instance of %@", providerClassName]];
            continue;
        }

        CLXAdapterMetadata *metadata = [[CLXAdapterMetadata alloc] initWithNetwork:networkName
                                                                    adapterVersion:provider.adapterVersion
                                                                 networkSdkVersion:provider.networkSdkVersion];
        [results addObject:metadata];
        [self.logger debug:[NSString stringWithFormat:@"Discovered adapter: network=%@, adapterVersion=%@, networkSdkVersion=%@",
                           networkName, provider.adapterVersion, provider.networkSdkVersion]];
    }

    return [results copy];
}

#pragma mark - Private

- (nullable Class)loadClassWithNamespace:(NSString *)namespace className:(NSString *)className {
    NSString *fullClassName = [NSString stringWithFormat:@"%@.%@", namespace, className];
    Class cls = NSClassFromString(fullClassName);
    if (cls) {
        return cls;
    }

    cls = NSClassFromString(className);
    if (cls) {
        return cls;
    }

    [self.logger debug:[NSString stringWithFormat:@"Metadata provider not found: %@ (adapter may not be installed)", className]];
    return nil;
}

@end
