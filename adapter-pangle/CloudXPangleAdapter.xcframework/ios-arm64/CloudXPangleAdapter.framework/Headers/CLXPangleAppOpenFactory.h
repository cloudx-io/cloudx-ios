//
//  CLXPangleAppOpenFactory.h
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
 * Factory for creating Pangle app open adapters.
 * App open ads use the interstitial factory protocol but back the format with
 * Pangle's dedicated PAGLAppOpenAd.
 */
@interface CLXPangleAppOpenFactory : CLXAdapterInterstitialFactory
@end

NS_ASSUME_NONNULL_END
