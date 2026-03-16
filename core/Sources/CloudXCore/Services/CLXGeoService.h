#import <Foundation/Foundation.h>

@class CLXGeoApi;
@class CLXGeoInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * Geo service responsible for fetching and processing geo data.
 * Orchestrates geo header fetching via CLXGeoApi and processes results into CLXGeoInfo.
 */
@interface CLXGeoService : NSObject

/**
 * Initializes the geo service with configuration and API client.
 * @param headerMapping Source-to-target geo header mapping from server config
 * @param geoApi The geo API client for fetching headers
 * @return An initialized CLXGeoService instance
 */
- (instancetype)initWithHeaderMapping:(NSDictionary<NSString *, NSString *> *)headerMapping
                               geoApi:(CLXGeoApi *)geoApi;

/**
 * Fetches geo headers and processes them into GeoInfo.
 * @param completion Completion handler with processed GeoInfo (never nil, returns empty on failure)
 */
- (void)fetchAndProcessGeo:(void(^)(CLXGeoInfo *geoInfo))completion;

@end

NS_ASSUME_NONNULL_END
