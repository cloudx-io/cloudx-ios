//
//  CLXMolocoInterstitialFactory.h
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
 * Factory for creating Moloco interstitial adapters.
 */
@interface CLXMolocoInterstitialFactory : CLXAdapterInterstitialFactory
@end

NS_ASSUME_NONNULL_END
