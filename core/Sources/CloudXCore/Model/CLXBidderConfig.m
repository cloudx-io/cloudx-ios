//
//  CloudXBidderConfig.m
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <CloudXCore/CLXBidderConfig.h>

@implementation CLXBidderConfig

- (instancetype)initWithInitializationData:(NSDictionary<NSString *, id> *)initializationData
                                 networkName:(NSString *)networkName {
    self = [super init];
    if (self) {
        _initializationData = [initializationData copy];
        _networkName = [networkName copy];
    }
    return self;
}

@end 
