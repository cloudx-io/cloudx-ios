/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidAdSource.h
 * @brief Bid ad source implementation
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXError.h>

@class CLXBidResponseBid, CLXBidResponse, CLXAd, CLXEnvironmentConfig;
@protocol CLXAdEventReporting;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXBidNetworkService;

/**
 * Error types for bid ad source operations
 */
typedef NS_ENUM(NSInteger, CLXBidAdSourceError) {
    /// Generic no-fill error when multiple bids fail
    CLXBidAdSourceErrorNoBid = 0,
    /// Specific error when a single bid's adapter fails to create
    /// Used to surface more detailed error information when there's only one bid
    CLXBidAdSourceErrorAdapterCreationFailed = 1
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
@property (nonatomic, copy, readonly) id _Nullable (^createBidAd)(NSError * _Nullable * _Nullable);
@property (nonatomic, strong, readonly, nullable) CLXAd *clxAd;

- (instancetype)initWithPrice:(double)price
                   auctionId:(nullable NSString *)auctionId
                      dealId:(nullable NSString *)dealId
                     latency:(double)latency
                         nurl:(nullable NSString *)nurl
                        bidID:(NSString *)bidID
                          bid:(CLXBidResponseBid *)bid
                  networkName:(NSString *)networkName
                       clxAd:(nullable CLXAd *)clxAd
                  createBidAd:(id _Nullable (^)(NSError * _Nullable * _Nullable error))createBidAd;

@end

/**
 * Protocol for bid ad source operations
 */
@protocol CLXBidAdSourceProtocol <NSObject>

- (void)requestBidWithAdUnitID:(NSString *)adUnitID
              storedImpressionId:(NSString *)storedImpressionId
            localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                       auctionId:(NSString *)auctionId
                      successWin:(BOOL)successWin
                   correlationId:(NSString *)correlationId
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
 * @param adUnitId Ad unit identifier
 * @param dealID Deal identifier (optional)
 * @param hasCloseButton Whether the ad has a close button
 * @param publisherID Publisher identifier
 * @param adType Type of ad
 * @param bidTokenSources Dictionary of bid token sources by adapter name
 * @param nativeAdRequirements Native ad requirements (optional)
 * @param bidRequestTimeout Timeout in seconds for HTTP request and OpenRTB tmax (0 = use session default)
 * @param reportingService Reporting service for events
 * @param createBidAd Block to create bid ads
 * @return Initialized bid ad source
 */
- (instancetype)initWithUserID:(nullable NSString *)userID
                      adUnitId:(NSString *)adUnitId
                        dealID:(nullable NSString *)dealID
                 hasCloseButton:(BOOL)hasCloseButton
                   publisherID:(NSString *)publisherID
                        adType:(NSInteger)adType
                bidTokenSources:(NSDictionary<NSString *, CLXBidTokenSource *> *)bidTokenSources
         nativeAdRequirements:(nullable id)nativeAdRequirements
            bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
               reportingService:(id<CLXAdEventReporting>)reportingService
                   createBidAd:(id _Nullable (^)(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSNumber * _Nullable mtype, NSError * _Nullable * _Nullable error))createBidAd;

/**
 * Initialize a new bid ad source with arbiter bid request opt-in.
 * @param userID User identifier
 * @param adUnitId Ad unit identifier
 * @param dealID Deal identifier (optional)
 * @param hasCloseButton Whether the ad has a close button
 * @param publisherID Publisher identifier
 * @param adType Type of ad
 * @param bidTokenSources Dictionary of bid token sources by adapter name
 * @param nativeAdRequirements Native ad requirements (optional)
 * @param bidRequestTimeout Timeout in seconds for HTTP request and OpenRTB tmax (0 = use session default)
 * @param arbiterEnabled Whether bid requests should opt into encrypted CloudX bid payloads for arbiter.
 * @param reportingService Reporting service for events
 * @param createBidAd Block to create bid ads
 * @return Initialized bid ad source
 */
- (instancetype)initWithUserID:(nullable NSString *)userID
                      adUnitId:(NSString *)adUnitId
                        dealID:(nullable NSString *)dealID
                 hasCloseButton:(BOOL)hasCloseButton
                   publisherID:(NSString *)publisherID
                        adType:(NSInteger)adType
                bidTokenSources:(NSDictionary<NSString *, CLXBidTokenSource *> *)bidTokenSources
         nativeAdRequirements:(nullable id)nativeAdRequirements
            bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                arbiterEnabled:(BOOL)arbiterEnabled
               reportingService:(id<CLXAdEventReporting>)reportingService
                   createBidAd:(id _Nullable (^)(NSString *adId, NSString *bidId, NSString *adm, NSDictionary<NSString *, NSString *> *adapterExtras, NSString * _Nullable burl, BOOL hasCloseButton, NSString *network, NSNumber * _Nullable mtype, NSError * _Nullable * _Nullable error))createBidAd;

@end

NS_ASSUME_NONNULL_END
