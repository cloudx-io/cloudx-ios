//
//  CLXDigitalTurbineInitializer.h
//  CloudXDigitalTurbineAdapter
//

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Bootstraps the underlying Digital Turbine SDK from CloudX server-side
 * provisioning. Reads `app_id` from `CLXBidderConfig.initializationData` and
 * routes the completion through CloudX's `CLXAdNetworkInitializer` contract.
 */
@interface CLXDigitalTurbineInitializer : CLXAdNetworkInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
