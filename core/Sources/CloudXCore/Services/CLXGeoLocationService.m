#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXLogger.h>
#import <CoreLocation/CoreLocation.h>

@interface CLXGeoLocationService () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXGeoLocationService

+ (instancetype)shared {
    static CLXGeoLocationService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXGeoLocationService"];
    }
    return self;
}

- (void)dealloc {
    [self.locationManager stopUpdatingLocation];
}

- (CLLocation *)currentLocation {
    return self.locationManager.location;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    if (@available(iOS 14.0, *)) {
        if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || 
            manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [manager startUpdatingLocation];
        }
        
        if (manager.authorizationStatus == kCLAuthorizationStatusDenied || 
            manager.authorizationStatus == kCLAuthorizationStatusRestricted) {
            [manager stopUpdatingLocation];
        }
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [manager startUpdatingLocation];
        }
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
            [manager stopUpdatingLocation];
        }
        #pragma clang diagnostic pop
    }
}

#pragma mark - Privacy Methods

- (nullable NSDictionary<NSString *, NSString *> *)geoHeaders {
    @try {
        NSDictionary *geoHeaders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreGeoHeadersKey];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Geo headers: %@", geoHeaders ?: @"(none)"]];
        return geoHeaders;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGeoLocationService] Failed to read geo headers: %@", exception.reason]];
        return nil;
    }
}

- (BOOL)isUSUser {
    NSDictionary *geoHeaders = [self geoHeaders];
    if (!geoHeaders) {
        [self.logger debug:@"📊 [CLXGeoLocationService] No geo headers - assuming non-US user"];
        return NO;
    }
    
    // Check cloudfront-viewer-country-iso3 header (matching Android implementation)
    id countryCodeObj = geoHeaders[@"cloudfront-viewer-country-iso3"];
    NSString *countryCode = [countryCodeObj isKindOfClass:[NSString class]] ? (NSString *)countryCodeObj : nil;
    BOOL isUS = [countryCode.lowercaseString isEqualToString:@"usa"];
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Country: %@, isUS: %@", countryCode ?: @"(none)", @(isUS)]];
    return isUS;
}

- (BOOL)isCaliforniaUser {
    if (![self isUSUser]) {
        [self.logger debug:@"📊 [CLXGeoLocationService] Not US user - not California"];
        return NO;
    }
    
    NSDictionary *geoHeaders = [self geoHeaders];
    id regionObj = geoHeaders[@"cloudfront-viewer-country-region"];
    NSString *region = [regionObj isKindOfClass:[NSString class]] ? (NSString *)regionObj : nil;
    BOOL isCalifornia = [region.lowercaseString isEqualToString:@"ca"];
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Region: %@, isCalifornia: %@", region ?: @"(none)", @(isCalifornia)]];
    return isCalifornia;
}

@end 