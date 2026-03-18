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
    if ([_networkName isEqualToString:@"testbidder"]) {
        return @"cloudXRenderer";
    }
    return _networkName;
}

- (NSDictionary<NSString *, id> *)getInitData {
    return self.bidderInitData;
}

@end 