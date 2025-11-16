//
//  CLXMolocoBaseFactory.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Base factory class for Moloco adapters.
 * Provides common functionality for all Moloco adapter factories.
 */
@interface CLXMolocoBaseFactory : NSObject

/**
 * Resolves the correct Moloco placement ID from adapter extras or falls back to adId.
 * @param extras The adapter extras dictionary from the bid response
 * @param adId The fallback ad ID
 * @param logger The logger instance for the specific factory
 * @return The resolved Moloco placement ID
 */
+ (NSString *)resolveMolocoPlacementID:(NSDictionary<NSString *, NSString *> *)extras 
                          fallbackAdId:(NSString *)adId 
                                logger:(CLXLogger *)logger;

@end

NS_ASSUME_NONNULL_END

