#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Mintegral app open adapters.
 * App open ads use the interstitial factory protocol but back the format with
 * Mintegral's Splash ad (MTGSplashAD).
 */
@interface CLXMintegralAppOpenFactory : CLXAdapterInterstitialFactory
@end

NS_ASSUME_NONNULL_END
