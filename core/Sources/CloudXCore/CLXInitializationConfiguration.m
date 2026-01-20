//
//  CLXInitializationConfiguration.m
//  CloudXCore
//
//  Configuration for initializing the CloudX SDK.
//

#import "CLXInitializationConfiguration.h"

@implementation CLXInitializationConfigurationBuilder
@end

@interface CLXInitializationConfiguration ()
@property (nonatomic, copy, readwrite) NSString *appKey;
@property (nonatomic, copy, readwrite, nullable) NSString *pluginVersion;
@end

@implementation CLXInitializationConfiguration

+ (instancetype)configurationWithAppKey:(NSString *)appKey {
    return [self configurationWithAppKey:appKey builderBlock:nil];
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey
                           builderBlock:(void (^)(CLXInitializationConfigurationBuilder *builder))builderBlock {
    CLXInitializationConfiguration *config = [[CLXInitializationConfiguration alloc] init];
    config.appKey = appKey;

    if (builderBlock) {
        CLXInitializationConfigurationBuilder *builder = [[CLXInitializationConfigurationBuilder alloc] init];
        builderBlock(builder);
        config.pluginVersion = builder.pluginVersion;
    }

    return config;
}

@end
