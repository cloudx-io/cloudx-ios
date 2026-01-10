//
//  CLXInMobiInitializer.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

@class CLXSettings;

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the InMobi advertising network adapter.
 * Handles SDK initialization, configuration, and registration of adapter factories.
 */
@interface CLXInMobiInitializer : NSObject <CLXAdNetworkInitializer>

/**
 * SDK version of the InMobi SDK
 */
@property (nonatomic, strong, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, strong, readonly) NSString *network;

/**
 * Checks if the InMobi SDK is initialized and ready for use
 * @return YES if initialized, NO otherwise
 */
+ (BOOL)isInitialized;

/**
 * Factory method to create a new initializer instance
 * @return New initializer instance
 */
+ (instancetype)createInstance;

/**
 * Gets the current InMobi SDK version
 * @return SDK version string
 */
+ (NSString *)sdkVersion;

/**
 * Gets the partner name (tp parameter) from server configuration
 * @return Partner name string or nil if not configured
 */
+ (nullable NSString *)partnerName;

/**
 * Gets the placement IDs from server configuration
 * @return Array of placement ID strings or nil if not configured
 */
+ (nullable NSArray<NSString *> *)placementIds;

/**
 * Initializes the InMobi SDK with the provided configuration
 * @param config The bidder configuration containing account ID and placement IDs
 * @param testMode Whether test mode is enabled (from server deviceConfig)
 * @param completion Completion block called with success/failure result
 */
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

