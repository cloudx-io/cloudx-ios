#import <Foundation/Foundation.h>

@class CLXGeoInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGeoLocationService : NSObject

/**
 * Returns the shared singleton instance of GeoLocationService.
 * @return The shared GeoLocationService instance.
 */
+ (instancetype)shared;

/**
 * Initializes the geo location service with a specified UserDefaults instance.
 * @param userDefaults The UserDefaults instance to use for storing and retrieving geo data.
 * @return An initialized CLXGeoLocationService instance.
 */
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

/**
 * Sets the geo information for this session.
 * Called by SDK initialization after geo data is fetched.
 * @param geoInfo The fetched geo information
 */
- (void)setGeoInfo:(nullable CLXGeoInfo *)geoInfo;

/**
 * Gets raw geo headers from CLXGeoInfo for privacy compliance
 * @return Dictionary of raw CloudFront headers if available, nil otherwise
 * @discussion Used for determining user geography for privacy regulations (US/CA checks)
 */
- (nullable NSDictionary<NSString *, NSString *> *)geoHeaders;

/**
 * Gets processed geo data mapped to OpenRTB fields for bid requests
 * @return Dictionary of processed geo fields (city, zip, region, metro) if available, nil otherwise
 * @discussion Used for populating device.geo in bid requests
 */
- (nullable NSDictionary<NSString *, NSString *> *)processedGeoData;

/**
 * Determines if user is located in the United States
 * @return YES if user is in US based on geo headers, NO otherwise
 * @discussion Uses cloudfront-viewer-country-iso3 header for determination
 */
- (BOOL)isUSUser;

/**
 * Determines if user is located in California
 * @return YES if user is in California (US-CA), NO otherwise
 * @discussion Requires US user and cloudfront-viewer-country-region header = "CA"
 */
- (BOOL)isCaliforniaUser;

/**
 * Determines if user is located in a GDPR region (EU/EEA)
 * @return YES if GDPR applies to user based on geo headers, NO otherwise
 * @discussion Uses gdpr-applies header from CloudX geo endpoint for determination.
 *             Per IAB TCF spec, GDPR applies when user is in EU/EEA region.
 */
- (BOOL)isEUUser;

/**
 * Gets the ISO-3 country code from geo headers (e.g., "USA")
 * @return Country code or nil if not available
 */
- (nullable NSString *)deviceCountry;

@end

NS_ASSUME_NONNULL_END 