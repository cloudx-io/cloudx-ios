#import <CloudXCore/CLXGeoLocationService.h>
#import <CoreLocation/CoreLocation.h>

@interface CLXGeoLocationService () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
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

@end 