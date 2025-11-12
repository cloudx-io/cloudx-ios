#import <Foundation/Foundation.h>

@class CLXBidAdSourceResponse, CLXConfigImpressionModel;

NS_ASSUME_NONNULL_BEGIN

@interface CLXRillImpressionModel : NSObject

@property (nonatomic, readonly, strong, nullable) CLXBidAdSourceResponse *lastBidResponse;
@property (nonatomic, readonly, strong) CLXConfigImpressionModel *impModel;
@property (nonatomic, readonly, copy) NSString *adapterName;
@property (nonatomic, readonly) NSInteger loadBannerTimesCount;
@property (nonatomic, readonly, copy) NSString *placementID;

- (instancetype)initWithLastBidResponse:(nullable CLXBidAdSourceResponse *)lastBidResponse
                               impModel:(CLXConfigImpressionModel *)impModel
                            adapterName:(NSString *)adapterName
                   loadBannerTimesCount:(NSInteger)loadBannerTimesCount
                            placementID:(NSString *)placementID;

@end

NS_ASSUME_NONNULL_END 
