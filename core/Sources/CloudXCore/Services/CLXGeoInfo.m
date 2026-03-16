#import "CLXGeoInfo.h"

// Header keys for raw geo data
static NSString * const kHeaderKeyLatitude = @"cloudfront-viewer-latitude";
static NSString * const kHeaderKeyLongitude = @"cloudfront-viewer-longitude";
static NSString * const kHeaderKeyRegion = @"cloudfront-viewer-country-region";
static NSString * const kHeaderKeyCountry = @"cloudfront-viewer-country-iso3";
static NSString * const kHeaderKeyGdprApplies = @"gdpr-applies";

// Constants for privacy checks
static NSString * const kRegionCalifornia = @"CA";
static NSString * const kCountryUSA = @"USA";

@implementation CLXGeoInfo

+ (instancetype)emptyGeoInfo {
    return [[self alloc] initWithProcessedGeoInfo:@{}
                                      rawGeoInfo:@{}
                                     hashedGeoIp:nil];
}

- (instancetype)initWithProcessedGeoInfo:(NSDictionary<NSString *, NSString *> *)processedGeoInfo
                             rawGeoInfo:(NSDictionary<NSString *, NSString *> *)rawGeoInfo
                            hashedGeoIp:(nullable NSString *)hashedGeoIp {
    self = [super init];
    if (self) {
        _processedGeoInfo = [processedGeoInfo copy];
        _rawGeoInfo = [rawGeoInfo copy];
        _hashedGeoIp = [hashedGeoIp copy];
    }
    return self;
}

#pragma mark - Privacy Compliance Methods

- (BOOL)isUSUser {
    NSString *country = self.rawGeoInfo[kHeaderKeyCountry];
    return country && [country caseInsensitiveCompare:kCountryUSA] == NSOrderedSame;
}

- (BOOL)isCaliforniaUser {
    if (![self isUSUser]) {
        return NO;
    }

    NSString *region = self.rawGeoInfo[kHeaderKeyRegion];
    return region && [region caseInsensitiveCompare:kRegionCalifornia] == NSOrderedSame;
}

- (BOOL)isEUUser {
    NSString *gdprApplies = self.rawGeoInfo[kHeaderKeyGdprApplies];
    return gdprApplies && [gdprApplies caseInsensitiveCompare:@"true"] == NSOrderedSame;
}

#pragma mark - Geo Field Accessors

- (nullable NSNumber *)latitude {
    NSString *latString = self.rawGeoInfo[kHeaderKeyLatitude];
    if (latString && [latString isKindOfClass:[NSString class]] && latString.length > 0) {
        double val = [latString doubleValue];
        return (val == 0.0 && ![latString hasPrefix:@"0"]) ? nil : @(val);
    }
    return nil;
}

- (nullable NSNumber *)longitude {
    NSString *lonString = self.rawGeoInfo[kHeaderKeyLongitude];
    if (lonString && [lonString isKindOfClass:[NSString class]] && lonString.length > 0) {
        double val = [lonString doubleValue];
        return (val == 0.0 && ![lonString hasPrefix:@"0"]) ? nil : @(val);
    }
    return nil;
}

@end
