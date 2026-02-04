//
// CLXSDKConfigAdUnit.m
// CloudXCore
//

#import <CloudXCore/CLXSDKConfigAdUnit.h>

@implementation CLXSDKConfigAdUnit

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = @"";
        _name = @"";
        _bidResponseTimeoutMs = 10000;  // Match Android default
        _adLoadTimeoutMs = 10000;
        _bannerRefreshRateMs = 30000;
        _type = SDKConfigAdTypeUnknown;
        _hasCloseButton = NO;
        _firstImpressionPlacementSuffix = nil;
        _firstImpressionLoopIndexStart = 0;
        _firstImpressionLoopIndexEnd = 0;
        _nativeTemplate = CLXNativeTemplateDefault;
        _dealId = nil;
        _line_items = nil;
        _rewardAmount = 0;
        _rewardCurrency = nil;
        _rewardCallbackUrl = nil;
    }
    return self;
}

- (NSString *)ilrdDescription {
    return [NSString stringWithFormat:@"CLXSDKConfigAdUnit(id=%@, name=%@, type=%ld)",
            self.id ?: @"nil",
            self.name ?: @"nil",
            (long)self.type];
}

- (NSTimeInterval)bidRequestTimeoutSeconds {
    return self.bidResponseTimeoutMs > 0 ? self.bidResponseTimeoutMs / 1000.0 : 0;
}

@end 