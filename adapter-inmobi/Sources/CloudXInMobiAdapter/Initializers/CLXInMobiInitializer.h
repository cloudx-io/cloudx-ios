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
 * Initializes the InMobi SDK with the provided configuration
 * @param config The bidder configuration containing account ID and placement IDs
 * @param completion Completion block called with success/failure result
 */
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

