//
//  CLXVungleInterstitialFactory.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#import <CloudXCore/CLXAdapterInterstitialFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Vungle interstitial adapters.
 * Implements the CloudX adapter factory protocol for interstitial ads.
 */
@interface CLXVungleInterstitialFactory : CLXAdapterInterstitialFactory

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
@end

NS_ASSUME_NONNULL_END
