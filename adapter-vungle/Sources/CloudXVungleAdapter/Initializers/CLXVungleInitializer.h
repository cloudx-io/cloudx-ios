//
//  CLXVungleInitializer.h
//  CloudXVungleAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Vungle advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXVungleInitializer : NSObject <CLXAdNetworkInitializer>

/**
 * SDK version of the Vungle SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Checks if the Vungle SDK is initialized and ready for use
 * @return YES if initialized, NO otherwise
 */
+ (BOOL)isInitialized;

/**
 * Factory method to create a new initializer instance
 * @return New initializer instance
 */
+ (instancetype)createInstance;

/**
 * Gets the current Vungle SDK version
 * @return SDK version string
 */
+ (NSString *)sdkVersion;

/**
 * Initializes the Vungle SDK with the provided configuration
 * @param config The bidder configuration containing App ID and other settings
 * @param testMode Whether test mode is enabled (from server deviceConfig)
 * @param completion Completion block called with success/failure result
 */
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
