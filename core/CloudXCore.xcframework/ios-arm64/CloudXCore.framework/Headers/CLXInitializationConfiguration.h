//
//  CLXInitializationConfiguration.h
//  CloudXCore
//
//  Configuration for initializing the CloudX SDK.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXInitializationConfiguration;

/**
 * Builder for constructing CLXInitializationConfiguration instances.
 */
CLX_PUBLIC
@interface CLXInitializationConfigurationBuilder : NSObject

/**
 * Version of the plugin/framework wrapper (e.g., "flutter-1.2.0", "unity-2.3.1").
 * Used to identify which wrapper SDK is being used for debugging and analytics.
 */
@property (nonatomic, copy, nullable) NSString *pluginVersion;

@end

/**
 * Configuration for initializing the CloudX SDK.
 *
 * Use the builder block pattern to create an instance:
 * @code
 * CLXInitializationConfiguration *config =
 *     [CLXInitializationConfiguration configurationWithAppKey:@"your-app-key"
 *         builderBlock:^(CLXInitializationConfigurationBuilder *builder) {
 *             builder.pluginVersion = @"flutter-1.2.0";
 *         }];
 * @endcode
 */
CLX_PUBLIC
@interface CLXInitializationConfiguration : NSObject

/**
 * Identifier of the publisher app registered with CloudX.
 */
@property (nonatomic, copy, readonly) NSString *appKey;

/**
 * Version of the plugin/framework wrapper, if set.
 */
@property (nonatomic, copy, readonly, nullable) NSString *pluginVersion;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 * Creates a configuration with the specified app key.
 *
 * @param appKey Identifier of the publisher app registered with CloudX.
 * @return A new configuration instance.
 */
+ (instancetype)configurationWithAppKey:(NSString *)appKey;

/**
 * Creates a configuration with the specified app key and builder block.
 *
 * @param appKey Identifier of the publisher app registered with CloudX.
 * @param builderBlock Block to configure additional options via the builder.
 * @return A new configuration instance.
 */
+ (instancetype)configurationWithAppKey:(NSString *)appKey
                           builderBlock:(nullable void (^)(CLXInitializationConfigurationBuilder *builder))builderBlock
    NS_SWIFT_NAME(configuration(appKey:builderBlock:));

@end

NS_ASSUME_NONNULL_END
