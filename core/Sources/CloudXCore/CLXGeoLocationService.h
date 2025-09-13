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
 * Gets geo headers from UserDefaults for privacy compliance
 * @return Dictionary of geo headers if available, nil otherwise
 * @discussion Used for determining user geography for privacy regulations
 */
- (nullable NSDictionary<NSString *, NSString *> *)geoHeaders;

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

@end

NS_ASSUME_NONNULL_END 