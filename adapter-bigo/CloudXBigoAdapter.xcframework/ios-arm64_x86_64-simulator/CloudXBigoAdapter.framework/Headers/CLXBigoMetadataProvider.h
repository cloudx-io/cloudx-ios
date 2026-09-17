#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterMetadataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoMetadataProvider
 * @brief Reports the BIGO Ads adapter and network SDK versions to CloudXCore.
 * @discussion Discovered by name (`CLXBigoMetadataProvider`) so the SDK can include the
 *             installed adapter in the config request and gate compatibility.
 */
@interface CLXBigoMetadataProvider : CLXAdapterMetadataProvider
@end

NS_ASSUME_NONNULL_END
