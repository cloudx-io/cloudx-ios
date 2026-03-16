#import "CLXGeoService.h"
#import "CLXGeoApi.h"
#import "CLXGeoInfo.h"
#import <CloudXCore/CLXLogger.h>
#import <CommonCrypto/CommonDigest.h>

// Header key for geo IP
static NSString * const kHeaderKeyGeoIp = @"x-amzn-remapped-x-forwarded-for";

@interface CLXGeoService ()
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *headerMapping;
@property (nonatomic, strong) CLXGeoApi *geoApi;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXGeoService

- (instancetype)initWithHeaderMapping:(NSDictionary<NSString *, NSString *> *)headerMapping
                               geoApi:(CLXGeoApi *)geoApi {
    self = [super init];
    if (self) {
        _headerMapping = [headerMapping copy];
        _geoApi = geoApi;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXGeoService"];
    }
    return self;
}

- (void)fetchAndProcessGeo:(void(^)(CLXGeoInfo *geoInfo))completion {
    // Both geoApi and completion are nonnull per NS_ASSUME_NONNULL_BEGIN
    // No defensive checks needed - trust the type system
    [self.geoApi fetchGeoHeaders:^(NSDictionary<NSString *,NSString *> * _Nullable headers, NSError * _Nullable error) {
        if (error || !headers) {
            [self.logger warn:[NSString stringWithFormat:@"Failed to fetch geo headers: %@", error.localizedDescription ?: @"unknown error"]];
            completion([CLXGeoInfo emptyGeoInfo]);
            return;
        }

        CLXGeoInfo *geoInfo = [self processGeoHeaders:headers];
        completion(geoInfo);
    }];
}

#pragma mark - Private Methods

- (CLXGeoInfo *)processGeoHeaders:(NSDictionary<NSString *, NSString *> *)rawHeaders {
    NSDictionary<NSString *, NSString *> *processedGeoInfo = [self mapGeoHeaders:rawHeaders];
    NSString *hashedGeoIp = [self extractAndHashGeoIp:rawHeaders];

    [self.logger debug:[NSString stringWithFormat:@"Mapped %lu geo headers: %@", (unsigned long)processedGeoInfo.count, processedGeoInfo]];
    if (hashedGeoIp) {
        [self.logger debug:[NSString stringWithFormat:@"Geo IP hash: %@", hashedGeoIp]];
    } else {
        [self.logger debug:@"Geo IP hash: (none)"];
    }

    return [[CLXGeoInfo alloc] initWithProcessedGeoInfo:processedGeoInfo
                                            rawGeoInfo:rawHeaders
                                           hashedGeoIp:hashedGeoIp];
}

- (NSDictionary<NSString *, NSString *> *)mapGeoHeaders:(NSDictionary<NSString *, NSString *> *)rawHeaders {
    NSMutableDictionary *mapped = [NSMutableDictionary dictionary];

    [self.headerMapping enumerateKeysAndObjectsUsingBlock:^(NSString *source, NSString *target, BOOL *stop) {
        NSString *value = rawHeaders[source];
        if (value) {
            mapped[target] = value;
        }
    }];

    return [mapped copy];
}

- (nullable NSString *)extractAndHashGeoIp:(NSDictionary<NSString *, NSString *> *)rawHeaders {
    NSString *geoIp = rawHeaders[kHeaderKeyGeoIp];
    if (!geoIp) {
        return nil;
    }

    return [self normalizeAndHash:geoIp];
}

- (NSString *)normalizeAndHash:(NSString *)input {
    // Normalize: lowercase and trim whitespace (matches Android normalizeAndHash)
    NSString *normalized = [[input lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // MD5 hash (matches Android default algo)
    const char *cStr = [normalized UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
#pragma clang diagnostic pop

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }

    return [hash copy];
}

@end
