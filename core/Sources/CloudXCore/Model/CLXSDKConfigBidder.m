//
// SDKConfigBidder.m
// CloudXCore
//

#import <CloudXCore/CLXSDKConfigBidder.h>

@implementation CLXSDKConfigBidder

- (instancetype)initWithBidderInitData:(NSDictionary<NSString *, id> *)bidderInitData
                    networkName:(NSString *)networkName {
    self = [super init];
    if (self) {
        _bidderInitData = [bidderInitData copy];
        _networkName = [networkName copy];
    }
    return self;
}

- (NSString *)networkNameMapped {
    // Map networkName to the correct key used in initializers dictionary
    if ([_networkName isEqualToString:@"testbidder"]) {
        return @"testbidder";
    } else if ([_networkName isEqualToString:@"googleAdManager"]) {
        return @"googleAdManager";
    } else if ([_networkName isEqualToString:@"meta"]) {
        return @"meta";
    } else if ([_networkName isEqualToString:@"mintegral"]) {
        return @"mintegral";
    } else if ([_networkName isEqualToString:@"cloudx"]) {
        return @"cloudx";
    } else if ([_networkName isEqualToString:@"prebidAdapter"]) {
        return @"prebidAdapter";
    } else if ([_networkName isEqualToString:@"prebidMobile"]) {
        return @"prebidAdapter";
    }
    return _networkName;
}

- (NSDictionary<NSString *, id> *)getInitData {
    return self.bidderInitData;
}

@end 