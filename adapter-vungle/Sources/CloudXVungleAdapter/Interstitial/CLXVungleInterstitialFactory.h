//
//  CLXVungleInterstitialFactory.h
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import <Foundation/Foundation.h>

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Vungle interstitial adapters.
 * Implements the CloudX adapter factory protocol for interstitial ads.
 */
@interface CLXVungleInterstitialFactory : NSObject <CLXAdapterInterstitialFactory>

/**
 * Logger instance for the factory
 * @return Shared logger instance
 */
+ (CLXLogger *)logger;

/**
 * Factory method to create a new factory instance
 * @return New factory instance
 */
+ (instancetype)createInstance;

/**
 * Creates a new Vungle interstitial adapter
 * @param adId The ad ID from the bid response
 * @param bidId The CloudX bid ID
 * @param adm The ad markup containing bid payload (if applicable)
 * @param extras Additional configuration parameters
 * @param delegate The CloudX adapter delegate
 * @return New interstitial adapter instance, or nil if creation failed
 */
- (nullable id<CLXAdapterInterstitial>)createWithAdId:(NSString *)adId
                                                bidId:(NSString *)bidId
                                                  adm:(NSString *)adm
                                               extras:(NSDictionary<NSString *, NSString *> *)extras
                                             delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
