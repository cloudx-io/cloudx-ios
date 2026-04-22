//
//  CLXMagniteInterstitialFactory.h
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
 * Factory for creating Magnite interstitial adapters.
 * Implements the CloudX adapter factory protocol for interstitial ads.
 */
@interface CLXMagniteInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
