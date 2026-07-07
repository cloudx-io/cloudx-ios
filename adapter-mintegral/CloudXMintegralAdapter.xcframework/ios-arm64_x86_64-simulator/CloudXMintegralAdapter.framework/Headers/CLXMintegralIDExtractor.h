//
//  CLXMintegralIDExtractor.h
//  CloudXMintegralAdapter
//
//  Shared utility for extracting Mintegral IDs from bid response extras.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Result of ID extraction containing both placementID and unitID.
 */
@interface CLXMintegralIDResult : NSObject

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly) NSString *unitID;
@property (nonatomic, copy, readonly, nullable) NSString *bidID;

- (instancetype)initWithPlacementID:(NSString *)placementID
                             unitID:(NSString *)unitID
                              bidID:(nullable NSString *)bidID;

@end

/**
 * Utility class for extracting Mintegral IDs from bid response adapter_extras.
 *
 * The server sends placement_id in adapter_extras which actually contains
 * the Mintegral unit_id (ad unit identifier). This utility handles the
 * extraction and provides consistent fallback logic across all ad formats.
 */
@interface CLXMintegralIDExtractor : NSObject

/**
 * Extracts Mintegral IDs from bid response extras.
 *
 * @param extras The adapter_extras dictionary from bid.ext.cloudx.adapter_extras
 * @param adId Fallback ad ID parameter (may be placementID_unitID format)
 * @param bidIdParam Fallback bid ID parameter
 * @param logger Logger for debug output
 * @return CLXMintegralIDResult containing placementID, unitID, and bidID
 *
 * @discussion
 * The server sends three distinct fields in adapter_extras:
 * - placement_id: Mintegral placement ID (e.g., "3139682")
 * - ad_unit_id: Mintegral unit/ad unit ID (e.g., "5402465")
 * - bid_id: Mintegral's bid ID for tracking
 *
 * Note: Bid token generation on iOS uses the no-argument method since
 * these IDs are not available during SDK initialization. The server
 * adds placement_id and ad_unit_id to the bid request to Mintegral.
 *
 * Extraction priority:
 * 1. Read placement_id and ad_unit_id from extras (primary source)
 * 2. Fall back to parsing adId parameter if extras are missing
 * 3. Use one for the other if only one is available
 */
+ (CLXMintegralIDResult *)extractIDsFromExtras:(nullable NSDictionary *)extras
                                          adId:(nullable NSString *)adId
                                    bidIdParam:(nullable NSString *)bidIdParam
                                        logger:(nullable id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
