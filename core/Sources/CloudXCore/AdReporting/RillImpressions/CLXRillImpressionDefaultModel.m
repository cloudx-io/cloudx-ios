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
    [resultString appendString:[(self.bidder ? self.bidder : @"") semicolon]];
    [resultString appendString:[(self.width ? [NSString stringWithFormat:@"%ld", (long)self.width] : @"") semicolon]];
    [resultString appendString:[(self.height ? [NSString stringWithFormat:@"%ld", (long)self.height] : @"") semicolon]];
    [resultString appendString:[(self.dealId ? self.dealId : @"dealId_absent_from_bid") semicolon]];
    [resultString appendString:[(self.creativeId ? self.creativeId : @"") semicolon]];
    [resultString appendString:[(self.cpmMicros ? [NSString stringWithFormat:@"%d", [self.cpmMicros intValue]] : @"0") semicolon]];
    [resultString appendString:[(self.responseTimeMillis ? [NSString stringWithFormat:@"%d", [self.responseTimeMillis intValue]] : @"0") semicolon]];
    [resultString appendString:[(self.releaseVersion ? self.releaseVersion : @"") semicolon]];
    [resultString appendString:[(self.auctionId ? self.auctionId : @"") semicolon]];
    [resultString appendString:[(self.accountId ? self.accountId : @"") semicolon]];
    [resultString appendString:[(self.organizationId ? self.organizationId : @"") semicolon]];
    [resultString appendString:[(self.applicationId ? self.applicationId : @"") semicolon]];
    [resultString appendString:[(self.placementId ? self.placementId : @"") semicolon]];
    [resultString appendString:[(self.deviceName ? self.deviceName : @"") semicolon]];
    [resultString appendString:[(self.deviceType ? self.deviceType : @"") semicolon]];
    [resultString appendString:[(self.osName ? self.osName : @"") semicolon]];
    [resultString appendString:[(self.osVersion ? self.osVersion : @"") semicolon]];
    [resultString appendString:[(self.sessionId ? self.sessionId : @"") semicolon]];
    [resultString appendString:[(self.ifa ? self.ifa : @"") semicolon]];
    [resultString appendString:[(self.loopIndex ? [NSString stringWithFormat:@"%ld", (long)self.loopIndex] : @"") semicolon]];
    [resultString appendString:[(self.testGroupName ? self.testGroupName : @"") semicolon]];
    return resultString;
}

@end 