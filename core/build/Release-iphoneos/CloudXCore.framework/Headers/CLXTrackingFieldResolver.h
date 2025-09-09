#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXSDKConfigResponse;
@class CLXBidAdSourceResponse;

/**
 * iOS equivalent of Android's TrackingFieldResolver
 * Provides server-driven, dynamic field resolution for Rill tracking payloads
 */
@interface CLXTrackingFieldResolver : NSObject

/**
 * Shared singleton instance
 */
+ (instancetype)shared;

/**
 * Sets the SDK configuration containing server-driven tracking field list
 * @param config The SDK config response from server
 */
- (void)setConfig:(CLXSDKConfigResponse *)config;

/**
 * Stores bid request JSON data for field resolution
 * @param auctionId The auction identifier
 * @param bidRequestJSON The raw bid request JSON dictionary
 */
- (void)setRequestData:(NSString *)auctionId bidRequestJSON:(NSDictionary *)bidRequestJSON;

/**
 * Stores bid response JSON data for field resolution
 * @param auctionId The auction identifier
 * @param bidResponseJSON The raw bid response JSON dictionary
 */
- (void)setResponseData:(NSString *)auctionId bidResponseJSON:(NSDictionary *)bidResponseJSON;

/**
 * Sets the winning bid ID for an auction
 * @param auctionId The auction identifier
 * @param bidId The winning bid identifier
 */
- (void)saveLoadedBid:(NSString *)auctionId bidId:(NSString *)bidId;

/**
 * Sets the loop index for an auction
 * @param auctionId The auction identifier
 * @param loopIndex The load attempt count
 */
- (void)setLoopIndex:(NSString *)auctionId loopIndex:(NSInteger)loopIndex;

/**
 * Sets session-level constant data
 * @param sessionId The session identifier
 * @param sdkVersion The SDK version string
 * @param deviceType The device type string
 * @param abTestGroup The A/B test group name
 */
- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
                 deviceType:(NSString *)deviceType
                abTestGroup:(NSString *)abTestGroup;

/**
 * Sets the hashed geo IP for privacy-safe tracking
 * @param hashedGeoIp The hashed geo IP string
 */
- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp;

/**
 * Builds the complete tracking payload using server-driven field list
 * @param auctionId The auction identifier
 * @return The semicolon-separated payload string, or nil if no tracking config
 */
- (nullable NSString *)buildPayload:(NSString *)auctionId;

/**
 * Gets the account ID for encryption
 * @return The account ID, or nil if not set
 */
- (nullable NSString *)getAccountId;

/**
 * Clears all stored data
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END
