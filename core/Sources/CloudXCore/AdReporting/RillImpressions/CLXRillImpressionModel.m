#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXConfigImpressionModel.h>

@implementation CLXRillImpressionModel

- (instancetype)initWithLastBidResponse:(CLXBidAdSourceResponse *)lastBidResponse
                               impModel:(CLXConfigImpressionModel *)impModel
                            adapterName:(NSString *)adapterName
                   loadBannerTimesCount:(NSInteger)loadBannerTimesCount
                            placementID:(NSString *)placementID {
    self = [super init];
    if (self) {
        _lastBidResponse = lastBidResponse;
        _impModel = impModel;
        _adapterName = [adapterName copy];
        _loadBannerTimesCount = loadBannerTimesCount;
        _placementID = [placementID copy];
    }
    return self;
}

@end 