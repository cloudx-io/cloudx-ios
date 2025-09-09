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

@end

NS_ASSUME_NONNULL_END 