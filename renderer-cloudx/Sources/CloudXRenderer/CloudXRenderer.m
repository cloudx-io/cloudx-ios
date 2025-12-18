//
//  CloudXRenderer.m
//  CloudXRenderer
//
//  Renderer rendering adapter implementation
//

#import "CloudXRenderer.h"
#import "CLXRendererVersion.h"
#import <CloudXCore/CLXLogger.h>

@implementation CloudXRenderer

+ (NSString *)version {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRenderer"];
    [logger debug:[NSString stringWithFormat:@"CloudXRenderer version requested: %@", CLXRendererVersion]];
    return CLXRendererVersion;
}

+ (NSString *)networkName {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRenderer"];
    NSString *networkName = @"renderer";
    [logger debug:[NSString stringWithFormat:@"CloudXRenderer network name requested: %@", networkName]];
    return networkName;
}

@end