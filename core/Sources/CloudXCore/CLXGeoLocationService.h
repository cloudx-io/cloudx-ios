#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * GeoLocationService provides location services for the CloudX SDK.
 * It manages CoreLocation permissions and provides current location data.
 */
@interface CLXGeoLocationService : NSObject

/**
 * Returns the current location if available and authorized.
 * @return The current CLLocation object, or nil if not available.
 */
@property (nonatomic, readonly, nullable) CLLocation *currentLocation;

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
 * Gets raw geo headers from UserDefaults for privacy compliance
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
 * Gets the user's country code from geo headers
 * @return The country code (e.g., "USA", "GBR") if available, nil otherwise
 * @discussion Uses cloudfront-viewer-country-iso3 header for country determination
 */
- (nullable NSString *)countryCode;

/**
 * Gets the user's region/state code from processed geo data
 * @return The region code (e.g., "CA", "NY") if available, nil otherwise
 * @discussion Maps to OpenRTB device.geo.region field
 */
- (nullable NSString *)region;

/**
 * Gets the user's city from processed geo data
 * @return The city name if available, nil otherwise
 * @discussion Maps to OpenRTB device.geo.city field
 */
- (nullable NSString *)city;

/**
 * Gets the user's postal/zip code from processed geo data
 * @return The zip code if available, nil otherwise
 * @discussion Maps to OpenRTB device.geo.zip field
 */
- (nullable NSString *)zip;

/**
 * Gets the user's DMA (Designated Market Area) code from processed geo data
 * @return The metro/DMA code if available, nil otherwise
 * @discussion Maps to OpenRTB device.geo.metro field
 */
- (nullable NSString *)metro;

@end

NS_ASSUME_NONNULL_END 