//
//  CLXInMobiInterstitialFactory.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating InMobi interstitial ad adapters.
 */
@interface CLXInMobiInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

/**
 * Creates a new instance of the interstitial factory
 * @return New factory instance
 */
+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

