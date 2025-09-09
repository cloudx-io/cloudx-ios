#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdType.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXBidNetworkService <NSObject>

@property (nonatomic, assign) BOOL isCDPEndpointEmpty;

- (void)createBidRequestWithAdUnitID:(NSString *)adUnitID
                   storedImpressionId:(NSString *)storedImpressionId
                               adType:(CLXAdType)adType
                               dealID:(nullable NSString *)dealID
                             bidFloor:(float)bidFloor
                          publisherID:(NSString *)publisherID
                               userID:(NSString *)userID
                          adapterInfo:(NSDictionary *)adapterInfo
                nativeAdRequirements:(nullable id)nativeAdRequirements
                                 tmax:(nullable NSNumber *)tmax
                            impModel:(nullable CLXConfigImpressionModel *)impModel
                           completion:(void (^)(id _Nullable bidRequest, NSError * _Nullable error))completion;

- (void)startAuctionWithBidRequest:(id)bidRequest
                            appKey:(NSString *)appKey
                        completion:(void (^)(CLXBidResponse * _Nullable response, NSError * _Nullable error))completion;

- (void)startCDPFlowWithBidRequest:(id)bidRequest
                       completion:(void (^)(id _Nullable enrichedBidRequest, NSError * _Nullable error))completion;

@end

@interface CLXBidNetworkServiceClass : NSObject <CLXBidNetworkService>

@property (nonatomic, assign) BOOL isCDPEndpointEmpty;

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                           cdpEndpointUrl:(NSString *)cdpEndpointUrl;

@end

NS_ASSUME_NONNULL_END 
