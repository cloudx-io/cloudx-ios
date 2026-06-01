//
//  CLXPangleInterstitialFactory.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Pangle interstitial adapters.
 */
@interface CLXPangleInterstitialFactory : CLXAdapterInterstitialFactory
@end

NS_ASSUME_NONNULL_END
