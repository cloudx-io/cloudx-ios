/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidAdSource.h
 * @brief Bid ad source implementation
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXError.h>

@class CLXBidResponseBid, CLXBiddingConfigRequest, CLXBidResponse;
@protocol CLXAdEventReporting;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXBidNetworkService;
@protocol CLXAppSessionService;
@protocol AdEventReporting;

/**
 * Error types for bid ad source operations
 */
typedef NS_ENUM(NSInteger, CLXBidAdSourceError) {
    CLXBidAdSourceErrorNoBid = 0
};

/**
 * Response structure for bid requests
 */
@interface CLXBidAdSourceResponse : NSObject

@property (nonatomic, assign, readonly) double price;
@property (nonatomic, copy, readonly, nullable) NSString *auctionId;
@property (nonatomic, copy, readonly, nullable) NSString *dealId;
@property (nonatomic, assign, readonly) double latency;
@property (nonatomic, copy, readonly, nullable) NSString *nurl;
@property (nonatomic, copy, readonly) NSString *bidID;
@property (nonatomic, copy, readonly) NSString *networkName;
@property (nonatomic, strong, readonly) CLXBidResponseBid *bid;
@property (nonatomic, strong, readonly) CLXBiddingConfigRequest *bidRequest;
@property (nonatomic, copy, readonly) id (^createBidAd)(void);

- (instancetype)initWithPrice:(double)price
                   auctionId:(nullable NSString *)auctionId
                      dealId:(nullable NSString *)dealId
                     latency:(double)latency
                         nurl:(nullable NSString *)nurl
                        bidID:(NSString *)bidID
                          bid:(CLXBidResponseBid *)bid
                   bidRequest:(CLXBiddingConfigRequest *)bidRequest
                  networkName:(NSString *)networkName
                  createBidAd:(id (^)(void))createBidAd;

@end

/**
 * Protocol for bid ad source operations
 */
@protocol CLXBidAdSourceProtocol <NSObject>

- (void)requestBidWithAdUnitID:(NSString *)adUnitID
              storedImpressionId:(NSString *)storedImpressionId
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                      successWin:(BOOL)successWin
                      completion:(void (^)(CLXBidAdSourceResponse * _Nullable response, NSError * _Nullable error))completion;

/**
 * Returns the current bid response containing all bids in the waterfall.
 * This is needed for LURL firing to access losing bids.
 */
- (nullable CLXBidResponse *)getCurrentBidResponse;

@end

/**
 * CLXBidAdSource implements the CLXBidAdSourceProtocol and handles bid requests,
 * auction participation, and ad creation.
 */
@interface CLXBidAdSource : NSObject <CLXBidAdSourceProtocol>

/**
 * Initialize a new bid ad source
 * @param userID User identifier
 * @param placementID Placement identifier
 * @param dealID Deal identifier (optional)
 * @param hasCloseButton Whether the ad has a close button
 * @param publisherID Publisher identifier
 * @param adType Type of ad
 * @param bidTokenSources Dictionary of bid token sources by adapter name
 * @param nativeAdRequirements Native ad requirements (optional)
 * @param tmax Timeout for bid requests (optional)
 * @param createBidAd Block to create bid ads
 * @return Initialized bid ad source
 */
- (instancetype)initWithUserID:(nullable NSString *)userID
                   placementID:(NSString *)placementID
                        dealID:(nullable NSString *)dealID
                 hasCloseButton:(BOOL)hasCloseButton
                   publisherID:(NSString *)publisherID
                        adType:(NSInteger)adType
                bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
         nativeAdRequirements:(nullable id)nativeAdRequirements
                          tmax:(nullable NSNumber *)tmax
               reportingService:(id<CLXAdEventReporting>)reportingService
                   createBidAd:(id (^)(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString *burl, BOOL hasCloseButton, NSString *network))createBidAd;

@end

NS_ASSUME_NONNULL_END 
