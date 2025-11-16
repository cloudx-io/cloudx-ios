//
//  CLXVungleRewardedFactory.h
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
 * Factory for creating Vungle rewarded adapters.
 * Implements the CloudX adapter factory protocol for rewarded ads.
 */
@interface CLXVungleRewardedFactory : NSObject <CLXAdapterRewardedFactory>

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
 * Creates a new Vungle rewarded adapter
 * @param adId The ad ID from the bid response
 * @param bidId The CloudX bid ID
 * @param adm The ad markup containing bid payload (if applicable)
 * @param extras Additional configuration parameters
 * @param delegate The CloudX adapter delegate
 * @return New rewarded adapter instance, or nil if creation failed
 */
- (nullable id<CLXAdapterRewarded>)createWithAdId:(NSString *)adId
                                            bidId:(NSString *)bidId
                                              adm:(NSString *)adm
                                           extras:(NSDictionary<NSString *, NSString *> *)extras
                                         delegate:(id<CLXAdapterRewardedDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
