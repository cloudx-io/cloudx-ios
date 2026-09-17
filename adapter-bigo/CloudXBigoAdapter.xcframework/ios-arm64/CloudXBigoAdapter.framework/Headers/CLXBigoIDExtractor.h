//
//  CLXBigoIDExtractor.h
//  CloudXBigoAdapter
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class CLXBigoIDExtractor
 * @brief Reads the BIGO Slot ID from a winning bid's adapter extras.
 * @discussion The CloudX backend stamps the Slot ID on every BIGO bid as
 *             `bid.ext.cloudx.adapter_extras.placement_id`; the SDK renders the bid's `adm`
 *             against that slot.
 */
@interface CLXBigoIDExtractor : NSObject

/**
 * @brief Extracts the BIGO Slot ID from bid adapter extras.
 * @param extras The `adapter_extras` dictionary of the winning bid.
 * @return The Slot ID, or an empty string when absent or not a string.
 */
+ (NSString *)slotIDFromExtras:(nullable NSDictionary *)extras;

@end

NS_ASSUME_NONNULL_END
