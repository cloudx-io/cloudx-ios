#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXLogger.h>
#import <CoreLocation/CoreLocation.h>

@interface CLXGeoLocationService () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@end

@implementation CLXGeoLocationService

+ (instancetype)shared {
    static CLXGeoLocationService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXGeoLocationService"];
        _userDefaults = userDefaults;
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
        NSDictionary *rawHeaders = [self.userDefaults dictionaryForKey:kCLXCoreRawGeoHeadersKey];
        return rawHeaders;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to read raw geo headers: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSDictionary<NSString *, NSString *> *)processedGeoData {
    @try {
        // Return processed geo data for bid request population (city, zip, region, metro)
        NSDictionary *processedData = [self.userDefaults dictionaryForKey:kCLXCoreProcessedGeoDataKey];
        return processedData;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to read processed geo data: %@", exception.reason]];
        return nil;
    }
}

- (BOOL)isUSUser {
    NSDictionary *geoHeaders = [self geoHeaders];
    if (!geoHeaders) {
        [self.logger debug:@"No geo headers - assuming non-US user"];
        return NO;
    }
    
    // Check cloudfront-viewer-country-iso3 header (matching Android implementation)
    id countryCodeObj = geoHeaders[@"cloudfront-viewer-country-iso3"];
    NSString *countryCode = [countryCodeObj isKindOfClass:[NSString class]] ? (NSString *)countryCodeObj : nil;
    BOOL isUS = [countryCode.lowercaseString isEqualToString:@"usa"];
    
    [self.logger verbose:[NSString stringWithFormat:@"Country: %@, isUS: %@", countryCode ?: @"(none)", @(isUS)]];
    return isUS;
}

- (BOOL)isCaliforniaUser {
    if (![self isUSUser]) {
        [self.logger debug:@"Not US user - not California"];
        return NO;
    }
    
    NSDictionary *geoHeaders = [self geoHeaders];
    id regionObj = geoHeaders[@"cloudfront-viewer-country-region"];
    NSString *region = [regionObj isKindOfClass:[NSString class]] ? (NSString *)regionObj : nil;
    BOOL isCalifornia = [region.lowercaseString isEqualToString:@"ca"];
    
    [self.logger verbose:[NSString stringWithFormat:@"Region: %@, isCalifornia: %@", region ?: @"(none)", @(isCalifornia)]];
    return isCalifornia;
}

- (BOOL)isEUUser {
    NSDictionary *geoHeaders = [self geoHeaders];
    if (!geoHeaders) {
        [self.logger debug:@"No geo headers - assuming non-EU user"];
        return NO;
    }
    
    // Check gdpr-applies header from CloudX geo endpoint
    // Per IAB TCF spec, this indicates if GDPR applies to the user's location
    id gdprAppliesObj = geoHeaders[@"gdpr-applies"];
    NSString *gdprApplies = nil;
    
    if ([gdprAppliesObj isKindOfClass:[NSString class]]) {
        gdprApplies = (NSString *)gdprAppliesObj;
    } else if ([gdprAppliesObj isKindOfClass:[NSNumber class]]) {
        gdprApplies = [(NSNumber *)gdprAppliesObj boolValue] ? @"true" : @"false";
    }
    
    // Accept "true" (case insensitive) or "1" as GDPR applies
    NSString *lowerValue = gdprApplies.lowercaseString;
    BOOL isEU = [lowerValue isEqualToString:@"true"] || [lowerValue isEqualToString:@"1"];
    
    [self.logger verbose:[NSString stringWithFormat:@"gdpr-applies: %@, isEU: %@", gdprApplies ?: @"(none)", @(isEU)]];
    return isEU;
}

- (nullable NSString *)countryCode {
    NSDictionary *geoHeaders = [self geoHeaders];
    if (!geoHeaders) {
        [self.logger debug:@"No geo headers - no country code available"];
        return nil;
    }
    
    // Get cloudfront-viewer-country-iso3 header
    id countryCodeObj = geoHeaders[@"cloudfront-viewer-country-iso3"];
    NSString *countryCode = [countryCodeObj isKindOfClass:[NSString class]] ? (NSString *)countryCodeObj : nil;
    
    // Handle placeholder values from simulator/development environment
    if ([countryCode isEqualToString:@"country"] || [countryCode isEqualToString:@"COUNTRY"]) {
        [self.logger debug:@"Detected placeholder country value, defaulting to USA"];
        countryCode = @"USA";
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Country code: %@", countryCode ?: @"(none)"]];
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
    
    return metro;
}

@end 