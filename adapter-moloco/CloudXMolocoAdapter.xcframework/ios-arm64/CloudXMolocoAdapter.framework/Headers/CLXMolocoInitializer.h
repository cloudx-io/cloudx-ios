//
//  CLXMolocoInitializer.h
//  CloudXMolocoAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Moloco advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXMolocoInitializer : CLXAdapterInitializer

/**
 * SDK version of the Moloco SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Gets the current Moloco SDK version
 * @return SDK version string
 */
+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
