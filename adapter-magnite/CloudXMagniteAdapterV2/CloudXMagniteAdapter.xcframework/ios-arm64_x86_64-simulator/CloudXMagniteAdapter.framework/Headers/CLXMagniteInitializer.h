//
//  CLXMagniteInitializer.h
//  CloudXMagniteAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Magnite advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXMagniteInitializer : CLXAdapterInitializer

/**
 * SDK version of the Magnite SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Gets the current Magnite SDK version
 * @return SDK version string
 */
+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
