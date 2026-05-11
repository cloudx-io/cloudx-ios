//
//  CLXMagniteInitializer.h
//  CloudXMagniteAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Initializer for the Magnite advertising network adapter.
 * Handles SDK initialization, configuration, and state management.
 */
@interface CLXMagniteInitializer : CLXAdNetworkInitializer

/**
 * SDK version of the Magnite SDK
 */
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/**
 * Network name identifier
 */
@property (nonatomic, copy, readonly) NSString *network;

/**
 * Checks if the Magnite SDK is initialized and ready for use
 * @return YES if initialized, NO otherwise
 */
+ (BOOL)isInitialized;

/**
 * Zone IDs from the SSP init response, used for Prebid Server bidder params.
 * @return Array of zone ID values, or nil if not yet initialized.
 */
+ (nullable NSArray *)zoneIds;

/**
 * Account ID from the SSP init response, used for Prebid Server bidder params.
 * @return Account ID as NSNumber, or nil if not yet initialized.
 */
+ (nullable NSNumber *)accountId;

/**
 * Site ID from the SSP init response, used for Prebid Server bidder params.
 * @return Site ID as NSNumber, or nil if not yet initialized.
 */
+ (nullable NSNumber *)siteId;

/**
 * Factory method to create a new initializer instance
 * @return New initializer instance
 */
/**
 * Gets the current Magnite SDK version
 * @return SDK version string
 */
+ (NSString *)sdkVersion;

/**
 * Initializes the Magnite SDK with the provided configuration
 * @param config The bidder configuration containing App ID and other settings
 * @param testMode Whether test mode is enabled (from server deviceConfig)
 * @param completion Completion block called with success/failure result
 */
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
