#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Geo information data model containing processed and raw geo data.
 * Provides privacy compliance methods (US/CA/EU detection) and geo field accessors.
 * Matches Android GeoInfo (merged GeoData + GeoInfo pattern).
 */
@interface CLXGeoInfo : NSObject

/**
 * Processed geo information mapped to OpenRTB fields.
 * Contains fields like city, region, zip, metro based on server configuration.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *processedGeoInfo;

/**
 * Raw geo headers from CloudFront.
 * Contains original headers like cloudfront-viewer-latitude, cloudfront-viewer-country-iso3, etc.
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *rawGeoInfo;

/**
 * Hashed geo IP extracted from x-amzn-remapped-x-forwarded-for header.
 * Used for user identification in analytics.
 */
@property (nonatomic, readonly, nullable) NSString *hashedGeoIp;

/**
 * Returns an empty GeoInfo instance.
 * @return Empty GeoInfo with no data
 */
+ (instancetype)emptyGeoInfo;

/**
 * Initializes GeoInfo with processed data, raw headers, and hashed IP.
 * @param processedGeoInfo Processed geo data mapped to OpenRTB fields
 * @param rawGeoInfo Raw CloudFront geo headers
 * @param hashedGeoIp Hashed geo IP (nullable)
 * @return An initialized CLXGeoInfo instance
 */
- (instancetype)initWithProcessedGeoInfo:(NSDictionary<NSString *, NSString *> *)processedGeoInfo
                             rawGeoInfo:(NSDictionary<NSString *, NSString *> *)rawGeoInfo
                            hashedGeoIp:(nullable NSString *)hashedGeoIp;

#pragma mark - Privacy Compliance Methods

/**
 * Determines if user is located in the United States.
 * @return YES if user is in US based on cloudfront-viewer-country-iso3 header
 */
- (BOOL)isUSUser;

/**
 * Determines if user is located in California.
 * @return YES if user is in California (US && region=CA)
 */
- (BOOL)isCaliforniaUser;

/**
 * Determines if user is located in a GDPR region (EU/EEA).
 * @return YES if GDPR applies based on gdpr-applies header
 */
- (BOOL)isEUUser;

#pragma mark - Geo Field Accessors

/**
 * Gets latitude from raw geo headers.
 * Reads from cloudfront-viewer-latitude header (NOT processed data).
 * @return Latitude as NSNumber or nil if not available
 */
- (nullable NSNumber *)latitude;

/**
 * Gets longitude from raw geo headers.
 * Reads from cloudfront-viewer-longitude header (NOT processed data).
 * @return Longitude as NSNumber or nil if not available
 */
- (nullable NSNumber *)longitude;

/**
 * Gets the ISO-3 country code from raw geo headers.
 * Reads from cloudfront-viewer-country-iso3 header.
 * @return Country ISO-3 code (e.g., "USA") or nil if not available
 */
- (nullable NSString *)countryISO3;

@end

NS_ASSUME_NONNULL_END
