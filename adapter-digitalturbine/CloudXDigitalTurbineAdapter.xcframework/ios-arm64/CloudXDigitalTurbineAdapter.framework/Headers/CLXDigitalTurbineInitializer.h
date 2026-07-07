//
//  CLXDigitalTurbineInitializer.h
//  CloudXDigitalTurbineAdapter
//

#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Bootstraps the underlying Digital Turbine SDK from CloudX server-side
 * provisioning. Reads `app_id` from adapter initialization params and
 * routes the completion through CloudX's `CLXAdapterInitializer` contract.
 */
@interface CLXDigitalTurbineInitializer : CLXAdapterInitializer

@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;

+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
