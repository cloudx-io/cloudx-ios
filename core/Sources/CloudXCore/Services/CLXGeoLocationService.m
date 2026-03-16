#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXLogger.h>
#import "CLXGeoInfo.h"

@interface CLXGeoLocationService ()
@property (nonatomic, strong) CLXLogger *logger;
@property (atomic, strong, nullable) CLXGeoInfo *geoInfo;
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
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXGeoLocationService"];
        _userDefaults = userDefaults;
    }
    return self;
}

#pragma mark - Privacy Methods

- (nullable NSDictionary<NSString *, NSString *> *)geoHeaders {
    return self.geoInfo.rawGeoInfo;
}

- (nullable NSDictionary<NSString *, NSString *> *)processedGeoData {
    return self.geoInfo.processedGeoInfo;
}

- (BOOL)isUSUser {
    return self.geoInfo ? [self.geoInfo isUSUser] : NO;
}

- (BOOL)isCaliforniaUser {
    return self.geoInfo ? [self.geoInfo isCaliforniaUser] : NO;
}

- (BOOL)isEUUser {
    return self.geoInfo ? [self.geoInfo isEUUser] : NO;
}

@end 