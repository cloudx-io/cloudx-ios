//
//  CLXVungleInitializer.h
//  CloudXVungleAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Vungle advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXVungleInitializer : CLXAdapterInitializer

/**
 * SDK version of the Vungle SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Gets the current Vungle SDK version
 * @return SDK version string
 */
+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
