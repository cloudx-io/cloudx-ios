//
//  CLXVungleBannerFactory.h
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
 * Factory for creating Vungle banner adapters.
 * Implements the CloudX adapter factory protocol for banner/MREC ads.
 */
@interface CLXVungleBannerFactory : NSObject <CLXAdapterBannerFactory>

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
 * Creates a new Vungle banner adapter
 * @param viewController The view controller for presenting the banner
 * @param type The banner type/size
 * @param adId The ad ID from the bid response
 * @param bidId The CloudX bid ID
 * @param adm The ad markup containing bid payload (if applicable)
 * @param hasClosedButton Whether the banner should have a close button
 * @param extras Additional configuration parameters
 * @param delegate The CloudX adapter delegate
 * @return New banner adapter instance, or nil if creation failed
 */
- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                     type:(CLXBannerType)type
                                                     adId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                          hasClosedButton:(BOOL)hasClosedButton
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
