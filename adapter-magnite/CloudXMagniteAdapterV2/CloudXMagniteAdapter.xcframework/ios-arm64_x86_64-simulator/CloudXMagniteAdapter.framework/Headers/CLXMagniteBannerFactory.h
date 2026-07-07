//
//  CLXMagniteBannerFactory.h
//  CloudXMagniteAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Magnite banner adapters.
 * Implements the CloudX adapter factory protocol for banner/MREC ads.
 */
@interface CLXMagniteBannerFactory : CLXAdapterBannerFactory

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
@end

NS_ASSUME_NONNULL_END
