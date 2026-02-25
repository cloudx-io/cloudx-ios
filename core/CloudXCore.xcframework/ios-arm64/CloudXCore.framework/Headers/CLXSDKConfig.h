#import <Foundation/Foundation.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXSDKConfigRequest.h>
#import <CloudXCore/CLXSDKConfigBidder.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations for classes defined in separate headers
@class CLXSDKConfigRequest;
@class CLXMetricsConfig;
@class CLXSDKConfigBidder;
@class CLXSDKConfigAdUnit;

// Forward declarations for classes defined in this file
@class CLXSDKConfigResponse;
@class CLXSDKConfigImp;
@class CLXSDKConfigBanner;
@class CLXSDKConfigFormat;
@class CLXSDKConfigSeatBid;
@class CLXSDKConfigBid;
@class CLXSDKConfigBidExt;
@class CLXSDKConfigCloudXExt;
@class CLXSDKConfigMeta;
@class CLXSDKConfigLineItem;
@class CLXSDKConfigQuantumValue;
@class CLXSDKConfigTargetingStrategy;
@class CLXSDKConfigTargeting;
@class CLXSDKConfigCondition;
@class CLXSDKConfigGeoBid;
@class CLXSDKConfigDeviceConfig;

@interface CLXSDKConfig : NSObject

@property (nonatomic, copy, nullable) NSString *appKey;
@property (nonatomic, assign) BOOL isDebug;
@property (nonatomic, copy, nullable) NSString *sessionID;
@property (nonatomic, copy, nullable) NSString *accountID;
@property (nonatomic, copy, nullable) NSArray<CLXSDKConfigBidder *> *bidders;
@property (nonatomic, copy, nullable) NSArray<CLXSDKConfigAdUnit *> *adUnits;
@property (nonatomic, copy, nullable) NSString *auctionEndpointURL;
@property (nonatomic, copy, nullable) NSString *organizationID;
@property (nonatomic, copy, nullable) NSString *impressionTrackerURL;
@property (nonatomic, strong, nullable) CLXMetricsConfig *metricsConfig;
@property (nonatomic, strong, nullable) NSArray<NSString *> *tracking;

- (instancetype)init;
- (instancetype)initWithAppKey:(NSString *)appKey isDebug:(BOOL)isDebug;

@end

@interface CLXSDKConfigImp : NSObject
@property (nonatomic, copy) NSString *id;
@property (nonatomic, strong, nullable) CLXSDKConfigBanner *banner;
- (instancetype)init;
@end

@interface CLXSDKConfigBanner : NSObject
@property (nonatomic, strong) NSArray<CLXSDKConfigFormat *> *format;
- (instancetype)init;
@end

@interface CLXSDKConfigFormat : NSObject
@property (nonatomic, assign) NSInteger w;
@property (nonatomic, assign) NSInteger h;
- (instancetype)initWithWidth:(NSInteger)width height:(NSInteger)height;
@end

// Response structure
@interface CLXSDKConfigResponse : NSObject

// ═══════════════════════════════════════════════════════════════════════════
// 1. Identity (required)
// ═══════════════════════════════════════════════════════════════════════════
@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy, nullable) NSString *organizationID;

// ═══════════════════════════════════════════════════════════════════════════
// 2. Endpoints (required)
// ═══════════════════════════════════════════════════════════════════════════
@property (nonatomic, copy) NSString *auctionEndpointURL;
@property (nonatomic, copy) NSString *impressionTrackerURL;
@property (nonatomic, copy) NSString *winLossNotificationURL;
@property (nonatomic, copy) NSString *geoDataEndpointURL;

// ═══════════════════════════════════════════════════════════════════════════
// 3. Core Config (required)
// ═══════════════════════════════════════════════════════════════════════════
@property (nonatomic, strong) NSArray<CLXSDKConfigBidder *> *bidders;
@property (nonatomic, strong) NSArray<CLXSDKConfigAdUnit *> *adUnits;

// ═══════════════════════════════════════════════════════════════════════════
// 4. Tracking & Geo (required)
// ═══════════════════════════════════════════════════════════════════════════
@property (nonatomic, strong) NSArray<NSString *> *tracking;
@property (nonatomic, copy) NSArray<CLXSDKConfigGeoBid *> *geoHeaders;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *winLossNotificationPayloadConfig;

// ═══════════════════════════════════════════════════════════════════════════
// 5. Optional Config
// ═══════════════════════════════════════════════════════════════════════════
@property (nonatomic, strong, nullable) CLXMetricsConfig *metricsConfig;
@property (nonatomic, strong, nullable) CLXSDKConfigDeviceConfig *deviceConfig;
/// Raw JSON response for dynamic field resolution (used by TrackingFieldResolver)
@property (nonatomic, strong, nullable) NSDictionary *rawJSON;

/// SDK init network call latency in milliseconds (for metrics tracking)
@property (nonatomic, assign) NSInteger sdkInitLatencyMs;

- (instancetype)init;
@end

@interface CLXSDKConfigSeatBid : NSObject
@property (nonatomic, strong) NSArray<CLXSDKConfigBid *> *bid;
@property (nonatomic, copy) NSString *seat;
- (instancetype)init;
@end

@interface CLXSDKConfigGeoBid : NSObject
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *target;
- (instancetype)init;
@end

@interface CLXSDKConfigBid : NSObject
@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *impid;
@property (nonatomic, assign) double price;
@property (nonatomic, copy) NSString *adm;
@property (nonatomic, copy) NSString *adid;
@property (nonatomic, strong) NSArray<NSString *> *adomain;
@property (nonatomic, copy) NSString *crid;
@property (nonatomic, assign) NSInteger w;
@property (nonatomic, assign) NSInteger h;
@property (nonatomic, strong, nullable) CLXSDKConfigBidExt *ext;
- (instancetype)init;
@end

@interface CLXSDKConfigBidExt : NSObject
@property (nonatomic, assign) double origbidcpm;
@property (nonatomic, copy, nullable) NSString *origbidcur;
@property (nonatomic, strong, nullable) CLXSDKConfigCloudXExt *cloudx;
- (instancetype)init;
@end

@interface CLXSDKConfigCloudXExt : NSObject
@property (nonatomic, strong, nullable) CLXSDKConfigMeta *meta;
@property (nonatomic, assign) NSInteger rank;
- (instancetype)init;
@end

@interface CLXSDKConfigMeta : NSObject
@property (nonatomic, copy) NSString *adaptercode;
- (instancetype)init;
@end

@interface CLXSDKConfigLineItem : NSObject
@property (nonatomic, copy, nullable) NSString *suffix;
@property (nonatomic, strong, nullable) CLXSDKConfigQuantumValue *targeting;
- (instancetype)init;
@end

@interface CLXSDKConfigQuantumValue : NSObject
@property (nonatomic, strong, nullable) CLXSDKConfigTargetingStrategy *targetingStrategy;
@property (nonatomic, strong, nullable) CLXSDKConfigTargeting *targeting;
- (instancetype)init;
- (nullable id)value;
@end

@interface CLXSDKConfigTargetingStrategy : NSObject
@property (nonatomic, copy) NSString *strategy;
- (instancetype)init;
@end

@interface CLXSDKConfigTargeting : NSObject
@property (nonatomic, copy) NSString *strategy;
@property (nonatomic, assign) BOOL conditionsAnd;
@property (nonatomic, copy) NSArray<CLXSDKConfigCondition *> *conditions;
- (instancetype)init;
@end

@interface CLXSDKConfigCondition : NSObject
@property (nonatomic, copy, nullable) NSArray<NSArray<NSDictionary<NSString *, CLXSDKConfigQuantumValue *> *> *> *whitelist;
@property (nonatomic, copy, nullable) NSArray<NSArray<NSDictionary<NSString *, CLXSDKConfigQuantumValue *> *> *> *blacklist;
@property (nonatomic, assign) BOOL conditionsAnd;
- (instancetype)init;
@end

/**
 * Device configuration from server init response
 * Controls test mode and debug logging on a per-device basis
 */
@interface CLXSDKConfigDeviceConfig : NSObject
/// Test mode value from server (0 = production, non-zero = test mode)
/// The value is passed through to bid requests as-is
@property (nonatomic, assign) NSInteger test;
/// Whether debug logging should be enabled for this device
@property (nonatomic, assign) BOOL debug;
- (instancetype)init;
@end

NS_ASSUME_NONNULL_END 
