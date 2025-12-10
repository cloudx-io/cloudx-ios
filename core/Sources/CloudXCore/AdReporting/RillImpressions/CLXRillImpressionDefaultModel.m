#import <CloudXCore/CLXRillImpressionDefaultModel.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/NSString+CLXSemicolon.h>

@implementation CLXRillImpressionDefaultModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _width = 320;
        _height = 50;
        _creativeId = @"creativeId_absent_from_bid";
        _releaseVersion = @"1.0.0";
            _deviceName = [CLXSystemInformation shared].model;
    _deviceType = DeviceTypeToString([CLXSystemInformation shared].deviceType);
    _osName = [CLXSystemInformation shared].os;
    _osVersion = [CLXSystemInformation shared].systemVersion;
    }
    return self;
}

- (NSString *)createParamString {
    NSMutableString *resultString = [NSMutableString string];
    [resultString appendString:[(self.bidder ? self.bidder : @"") clx_semicolon]];
    [resultString appendString:[(self.width ? [NSString stringWithFormat:@"%ld", (long)self.width] : @"") clx_semicolon]];
    [resultString appendString:[(self.height ? [NSString stringWithFormat:@"%ld", (long)self.height] : @"") clx_semicolon]];
    [resultString appendString:[(self.dealId ? self.dealId : @"dealId_absent_from_bid") clx_semicolon]];
    [resultString appendString:[(self.creativeId ? self.creativeId : @"") clx_semicolon]];
    [resultString appendString:[(self.cpmMicros ? [NSString stringWithFormat:@"%d", [self.cpmMicros intValue]] : @"0") clx_semicolon]];
    [resultString appendString:[(self.responseTimeMillis ? [NSString stringWithFormat:@"%d", [self.responseTimeMillis intValue]] : @"0") clx_semicolon]];
    [resultString appendString:[(self.releaseVersion ? self.releaseVersion : @"") clx_semicolon]];
    [resultString appendString:[(self.auctionId ? self.auctionId : @"") clx_semicolon]];
    [resultString appendString:[(self.accountId ? self.accountId : @"") clx_semicolon]];
    [resultString appendString:[(self.organizationId ? self.organizationId : @"") clx_semicolon]];
    [resultString appendString:[(self.applicationId ? self.applicationId : @"") clx_semicolon]];
    [resultString appendString:[(self.placementId ? self.placementId : @"") clx_semicolon]];
    [resultString appendString:[(self.deviceName ? self.deviceName : @"") clx_semicolon]];
    [resultString appendString:[(self.deviceType ? self.deviceType : @"") clx_semicolon]];
    [resultString appendString:[(self.osName ? self.osName : @"") clx_semicolon]];
    [resultString appendString:[(self.osVersion ? self.osVersion : @"") clx_semicolon]];
    [resultString appendString:[(self.sessionId ? self.sessionId : @"") clx_semicolon]];
    [resultString appendString:[(self.ifa ? self.ifa : @"") clx_semicolon]];
    [resultString appendString:[(self.testGroupName ? self.testGroupName : @"") clx_semicolon]];
    return resultString;
}

@end 