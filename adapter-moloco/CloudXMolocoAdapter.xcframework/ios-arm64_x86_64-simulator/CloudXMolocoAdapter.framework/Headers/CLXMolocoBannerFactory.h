//
//  CLXMolocoBannerFactory.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Moloco banner adapters.
 */
@interface CLXMolocoBannerFactory : CLXAdapterBannerFactory
@end

NS_ASSUME_NONNULL_END
