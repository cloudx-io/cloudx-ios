//
//  CloudXRenderer.m
//  CloudXRenderer
//
//  Renderer rendering adapter implementation
//

#import "CloudXRenderer.h"
#import <CloudXCore/CLXLogger.h>

@implementation CloudXRenderer

+ (NSString *)version {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRenderer"];
    NSString *version = @"3.0.1";
    [logger debug:[NSString stringWithFormat:@"CloudXRenderer version requested: %@", version]];
    return version;
}

+ (NSString *)networkName {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRenderer"];
    NSString *networkName = @"renderer";
    [logger debug:[NSString stringWithFormat:@"CloudXRenderer network name requested: %@", networkName]];
    return networkName;
}

@end