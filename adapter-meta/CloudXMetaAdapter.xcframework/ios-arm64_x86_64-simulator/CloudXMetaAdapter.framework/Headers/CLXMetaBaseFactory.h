//
//  CLXMetaBaseFactory.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-12-19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Base factory class for Meta adapters.
 * Follows Open/Closed Principle - open for extension, closed for modification.
 * Provides common functionality for all Meta adapter factories.
 */
@interface CLXMetaBaseFactory : NSObject

/**
 * Resolves the correct Meta placement ID from adapter extras or falls back to adId.
 * @param extras The adapter extras dictionary from the bid response
 * @param adId The fallback ad ID
 * @param logger The logger instance for the specific factory
 * @return The resolved Meta placement ID
 */
+ (NSString *)resolveMetaPlacementID:(NSDictionary<NSString *, NSString *> *)extras fallbackAdId:(NSString *)adId logger:(CLXLogger *)logger;

@end

NS_ASSUME_NONNULL_END
