#import <CloudXCore/CLXSKAdNetworkService.h>
#import <CloudXCore/CLXSystemInformation.h>

@interface CLXSKAdNetworkService ()
@property (nonatomic, copy) NSString *systemVersion;
@end

@implementation CLXSKAdNetworkService

@synthesize skadPlistIds = _skadPlistIds;
@synthesize versions = _versions;
@synthesize sourceApp = _sourceApp;

- (instancetype)initWithSystemVersion:(NSString *)systemVersion {
    self = [super init];
    if (self) {
        _systemVersion = [systemVersion copy];
    }
    return self;
}

- (NSArray<NSString *> *)versions {
    NSArray *everySkanVersions = @[ @"2.0", @"2.1", @"2.2", @"3.0", @"4.0" ];
    NSString *version = self.systemVersion;
    if ([self compareVersion:version to:@"16.1"] >= 0) {
        return everySkanVersions;
    } else if ([self compareVersion:version to:@"14.6"] >= 0) {
        return [everySkanVersions subarrayWithRange:NSMakeRange(0, everySkanVersions.count - 1)];
    } else if ([self compareVersion:version to:@"14.5"] >= 0) {
        return [everySkanVersions subarrayWithRange:NSMakeRange(0, everySkanVersions.count - 2)];
    } else if ([self compareVersion:version to:@"14.0"] >= 0) {
        return [everySkanVersions subarrayWithRange:NSMakeRange(0, everySkanVersions.count - 3)];
    } else {
        return @[];
    }
}

- (NSArray<NSString *> *)skadPlistIds {
    NSArray *skadItems = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SKAdNetworkItems"];
    if (![skadItems isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (NSDictionary *dict in skadItems) {
        NSString *skadId = dict[@"SKAdNetworkIdentifier"];
        if (skadId) {
            [ids addObject:skadId];
        }
    }
    return ids.count > 0 ? ids : nil;
}

- (NSString *)sourceApp {
    return [CLXSystemInformation shared].appBundleIdentifier;
}

// Helper for version comparison
- (NSInteger)compareVersion:(NSString *)v1 to:(NSString *)v2 {
    NSArray *v1Parts = [v1 componentsSeparatedByString:@"."];
    NSArray *v2Parts = [v2 componentsSeparatedByString:@"."];
    NSUInteger maxCount = MAX(v1Parts.count, v2Parts.count);
    for (NSUInteger i = 0; i < maxCount; i++) {
        NSInteger part1 = (i < v1Parts.count) ? [v1Parts[i] integerValue] : 0;
        NSInteger part2 = (i < v2Parts.count) ? [v2Parts[i] integerValue] : 0;
        if (part1 > part2) return 1;
        if (part1 < part2) return -1;
    }
    return 0;
}

@end 