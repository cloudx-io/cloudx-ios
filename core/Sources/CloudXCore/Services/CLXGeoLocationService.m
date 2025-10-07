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
        // Return raw CloudFront headers for privacy checks (US/CA detection)
        NSDictionary *rawHeaders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreRawGeoHeadersKey];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Raw geo headers: %@", rawHeaders ?: @"(none)"]];
        return rawHeaders;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGeoLocationService] Failed to read raw geo headers: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSDictionary<NSString *, NSString *> *)processedGeoData {
    @try {
        // Return processed geo data for bid request population (city, zip, region, metro)
        NSDictionary *processedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreProcessedGeoDataKey];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Processed geo data: %@", processedData ?: @"(none)"]];
        return processedData;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGeoLocationService] Failed to read processed geo data: %@", exception.reason]];
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

- (nullable NSString *)countryCode {
    NSDictionary *geoHeaders = [self geoHeaders];
    if (!geoHeaders) {
        [self.logger debug:@"📊 [CLXGeoLocationService] No geo headers - no country code available"];
        return nil;
    }
    
    // Get cloudfront-viewer-country-iso3 header
    id countryCodeObj = geoHeaders[@"cloudfront-viewer-country-iso3"];
    NSString *countryCode = [countryCodeObj isKindOfClass:[NSString class]] ? (NSString *)countryCodeObj : nil;
    
    // Handle placeholder values from simulator/development environment
    if ([countryCode isEqualToString:@"country"] || [countryCode isEqualToString:@"COUNTRY"]) {
        [self.logger debug:@"📊 [CLXGeoLocationService] Detected placeholder country value, defaulting to USA"];
        countryCode = @"USA";
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Country code: %@", countryCode ?: @"(none)"]];
    return countryCode;
}

- (nullable NSString *)region {
    NSDictionary *processedData = [self processedGeoData];
    if (!processedData) {
        return nil;
    }
    
    // Get region from processed geo data (e.g., "CA" for California)
    id regionObj = processedData[@"region"];
    NSString *region = [regionObj isKindOfClass:[NSString class]] ? (NSString *)regionObj : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Region: %@", region ?: @"(none)"]];
    return region;
}

- (nullable NSString *)city {
    NSDictionary *processedData = [self processedGeoData];
    if (!processedData) {
        return nil;
    }
    
    // Get city from processed geo data
    id cityObj = processedData[@"city"];
    NSString *city = [cityObj isKindOfClass:[NSString class]] ? (NSString *)cityObj : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] City: %@", city ?: @"(none)"]];
    return city;
}

- (nullable NSString *)zip {
    NSDictionary *processedData = [self processedGeoData];
    if (!processedData) {
        return nil;
    }
    
    // Get postal code from processed geo data
    id zipObj = processedData[@"zip"];
    NSString *zip = [zipObj isKindOfClass:[NSString class]] ? (NSString *)zipObj : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Zip: %@", zip ?: @"(none)"]];
    return zip;
}

- (nullable NSString *)metro {
    NSDictionary *processedData = [self processedGeoData];
    if (!processedData) {
        return nil;
    }
    
    // Get DMA (Designated Market Area) from processed geo data
    id metroObj = processedData[@"metro"];
    NSString *metro = [metroObj isKindOfClass:[NSString class]] ? (NSString *)metroObj : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGeoLocationService] Metro (DMA): %@", metro ?: @"(none)"]];
    return metro;
}

@end 