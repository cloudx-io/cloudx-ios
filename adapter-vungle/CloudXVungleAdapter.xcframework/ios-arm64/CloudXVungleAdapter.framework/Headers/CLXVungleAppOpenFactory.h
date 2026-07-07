//
//  CLXVungleAppOpenFactory.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterInterstitialFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Vungle App Open adapters.
 * Implements the CloudX adapter factory protocol for App Open ads.
 * App Open ads use the interstitial factory protocol but with dedicated App Open placements.
 */
@interface CLXVungleAppOpenFactory : CLXAdapterInterstitialFactory

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
@end

NS_ASSUME_NONNULL_END
