#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdType.h>

@class CLXErrorReporter;
@class CLXBidRequestPayload;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXBidNetworkService <NSObject>

/** POSTs the v2 SignalPayload with `X-CloudX-Payload-Version: 2`. */
- (void)sendBidRequestWithPayload:(CLXBidRequestPayload *)payload
                           appKey:(NSString *)appKey
                          timeout:(NSTimeInterval)timeout
                    correlationId:(NSString *)correlationId
                       completion:(void (^)(CLXBidResponse * _Nullable parsedResponse, NSDictionary * _Nullable rawJSON, NSError * _Nullable error))completion;

@end

@interface CLXBidNetworkServiceClass : NSObject <CLXBidNetworkService>

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl;

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                            errorReporter:(nullable CLXErrorReporter *)errorReporter;

- (instancetype)initWithAuctionEndpointUrl:(NSString *)auctionEndpointUrl
                            errorReporter:(nullable CLXErrorReporter *)errorReporter
                               urlSession:(NSURLSession *)urlSession;

@end

NS_ASSUME_NONNULL_END 
