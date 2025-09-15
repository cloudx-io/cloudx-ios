//
//  CLXVungleBaseFactory.h
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

/**
 * Base factory class for Vungle adapters.
 * Follows Open/Closed Principle - open for extension, closed for modification.
 * Provides common functionality for all Vungle adapter factories.
 */
@interface CLXVungleBaseFactory : NSObject

/**
 * Resolves the correct Vungle placement ID from adapter extras or falls back to adId.
 * @param extras The adapter extras dictionary from the bid response
 * @param adId The fallback ad ID
 * @param logger The logger instance for the specific factory
 * @return The resolved Vungle placement ID
 */
+ (NSString *)resolveVunglePlacementID:(NSDictionary<NSString *, NSString *> *)extras 
                            fallbackAdId:(NSString *)adId 
                                  logger:(CLXLogger *)logger;

/**
 * Validates that Vungle SDK is initialized and ready
 * @param logger The logger instance for logging errors
 * @return YES if initialized, NO otherwise
 */
+ (BOOL)validateVungleInitialization:(CLXLogger *)logger;

/**
 * Extracts bid payload from ADM (Ad Markup) if present
 * @param adm The ad markup string from the bid response
 * @param logger The logger instance for logging
 * @return The bid payload string, or nil if not present/invalid
 */
+ (nullable NSString *)extractBidPayloadFromADM:(NSString *)adm logger:(CLXLogger *)logger;

/**
 * Creates standardized user info dictionary for adapter creation
 * @param adId The ad ID
 * @param bidId The bid ID
 * @param placementId The resolved placement ID
 * @param extras The extras dictionary
 * @return User info dictionary for logging and debugging
 */
+ (NSDictionary *)createAdapterUserInfo:(NSString *)adId
                                  bidId:(NSString *)bidId
                            placementId:(NSString *)placementId
                                 extras:(NSDictionary<NSString *, NSString *> *)extras;

@end

NS_ASSUME_NONNULL_END
