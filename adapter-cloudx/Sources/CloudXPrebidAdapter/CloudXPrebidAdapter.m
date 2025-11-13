//
//  CloudXPrebidAdapter.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 rendering adapter implementation
//

#import "CloudXPrebidAdapter.h"
#import <CloudXCore/CLXLogger.h>

@implementation CloudXPrebidAdapter

+ (NSString *)version {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidAdapter"];
    NSString *version = @"3.0.1";
    [logger debug:[NSString stringWithFormat:@"CloudXPrebidAdapter version requested: %@", version]];
    return version;
}

+ (NSString *)networkName {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidAdapter"];
    NSString *networkName = @"prebid";
    [logger debug:[NSString stringWithFormat:@"CloudXPrebidAdapter network name requested: %@", networkName]];
    return networkName;
}

@end