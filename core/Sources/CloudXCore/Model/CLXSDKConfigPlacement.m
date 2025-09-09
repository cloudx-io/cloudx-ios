//
// SDKConfigPlacement.m
// CloudXCore
//

#import <CloudXCore/CLXSDKConfigPlacement.h>

@implementation CLXSDKConfigPlacement

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = @"";
        _name = @"";
        _bidResponseTimeoutMs = 3000;
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
    }
    return self;
}

- (NSString *)ilrdDescription {
    return [NSString stringWithFormat:@"SDKConfigPlacement(id=%@, name=%@, type=%ld)", 
            self.id ?: @"nil", 
            self.name ?: @"nil", 
            (long)self.type];
}

@end 