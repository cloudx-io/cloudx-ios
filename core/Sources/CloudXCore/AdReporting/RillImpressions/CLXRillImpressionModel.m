#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXConfigImpressionModel.h>

@implementation CLXRillImpressionModel

- (instancetype)initWithLastBidResponse:(CLXBidAdSourceResponse *)lastBidResponse
                               impModel:(CLXConfigImpressionModel *)impModel
                            adapterName:(NSString *)adapterName
                   loadBannerTimesCount:(NSInteger)loadBannerTimesCount
                               adUnitId:(NSString *)adUnitId {
    self = [super init];
    if (self) {
        _lastBidResponse = lastBidResponse;
        _impModel = impModel;
        _adapterName = [adapterName copy];
        _loadBannerTimesCount = loadBannerTimesCount;
        _adUnitId = [adUnitId copy];
    }
    return self;
}

@end 