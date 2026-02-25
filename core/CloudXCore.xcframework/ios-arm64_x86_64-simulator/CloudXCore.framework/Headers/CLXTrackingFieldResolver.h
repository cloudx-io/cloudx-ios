#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXPrivacyService;
@class CLXSDKConfigResponse;

// Public constant (matches Android companion object)
extern NSString * const SDK_PARAM_RESPONSE_IN_MILLIS;

/**
 * iOS equivalent of Android's TrackingFieldResolver
 * Provides server-driven, dynamic field resolution for tracking payloads
 */
@interface CLXTrackingFieldResolver : NSObject

/**
 * Shared singleton instance
 */
+ (instancetype)shared;

/**
 * Designated initializer with dependency injection for testability
 * @param privacyService The privacy service to use for personal data checks
 */
- (instancetype)initWithPrivacyService:(CLXPrivacyService *)privacyService;

#pragma mark - Config Setup

/**
 * Sets the SDK configuration from raw JSON for dynamic field resolution
 * This is the preferred method - stores raw JSON and traverses dynamically
 * @param configJSON The raw config JSON dictionary from server
 */
- (void)setConfigJSON:(NSDictionary *)configJSON;

/**
 * Sets the SDK configuration containing server-driven tracking field list
 * @param config The SDK config response from server
 * @note If config.rawJSON is available, it will be used for dynamic field resolution
 */
- (void)setConfig:(CLXSDKConfigResponse *)config;

#pragma mark - Data Methods (matches Android)

/**
 * Matches Android: setRequestData(auctionId: String, json: JSONObject)
 */
- (void)setRequestData:(NSString *)auctionId bidRequestJSON:(NSDictionary *)json;

/**
 * Matches Android: setResponseData(auctionId: String, json: JSONObject)
 */
- (void)setResponseData:(NSString *)auctionId bidResponseJSON:(NSDictionary *)json;

/**
 * Matches Android: setSdkParam(auctionId: String, key: String, value: String)
 */
- (void)setSdkParam:(NSString *)auctionId key:(NSString *)key value:(NSString *)value;

/**
 * Sets session-level constant data
 * iOS-specific: Android receives these in constructor
 */
- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
              pluginVersion:(nullable NSString *)pluginVersion
             deviceTypeName:(NSString *)deviceTypeName
             deviceTypeCode:(NSInteger)deviceTypeCode
                abTestGroup:(NSString *)abTestGroup
                  appBundle:(NSString *)appBundle;

/**
 * Sets the hashed geo IP for privacy-safe tracking
 */
- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp;

#pragma mark - Payload Building (matches Android)

/**
 * Matches Android: buildPayload(auctionId: String, bidId: String? = null): String
 */
- (nullable NSString *)buildPayload:(NSString *)auctionId bidId:(nullable NSString *)bidId;
- (nullable NSString *)buildPayload:(NSString *)auctionId;

#pragma mark - Field Resolution (matches Android)

/**
 * Matches Android: resolveField(auctionId: String, field: String, bidId: String? = null): Any?
 */
- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field bidId:(nullable NSString *)bidId;
- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field;

/**
 * Alternative signature for WinLossFieldResolver compatibility
 */
- (nullable id)resolveField:(NSString *)fieldPath forAuction:(NSString *)auctionId;

#pragma mark - Utility Methods

/**
 * Gets the account ID for encryption
 */
- (nullable NSString *)getAccountId;

/**
 * Clears all stored data
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END
