//
//  CLXVungleAppOpenFactory.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Vungle App Open adapters.
 * Implements the CloudX adapter factory protocol for App Open ads.
 * App Open ads use the interstitial factory protocol but with dedicated App Open placements.
 */
@interface CLXVungleAppOpenFactory : NSObject <CLXAdapterInterstitialFactory>

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
