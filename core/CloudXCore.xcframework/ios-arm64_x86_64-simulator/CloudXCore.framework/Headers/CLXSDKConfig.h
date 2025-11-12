#import <Foundation/Foundation.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXSDKConfigRequest.h>
#import <CloudXCore/CLXSDKConfigBidder.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations for classes defined in separate headers
@class CLXSDKConfigRequest;
@class CLXMetricsConfig;
@class CLXSDKConfigBidder;
@class CLXSDKConfigPlacement;

// Forward declarations for classes defined in this file
@class CLXSDKConfigResponse;
@class CLXSDKConfigEndpointObject;
@class CLXSDKConfigEndpointValue;
@class CLXSDKConfigImp;
@class CLXSDKConfigBanner;
@class CLXSDKConfigFormat;
@class CLXSDKConfigSeatBid;
@class CLXSDKConfigBid;
@class CLXSDKConfigBidExt;
@class CLXSDKConfigCloudXExt;
@class CLXSDKConfigMeta;
@class CLXSDKConfigEndpointQuantumValue;
@class CLXSDKConfigLineItem;
@class CLXSDKConfigQuantumValue;
@class CLXSDKConfigTargetingStrategy;
@class CLXSDKConfigTargeting;
@class CLXSDKConfigCondition;
@class CLXSDKConfigKeyValueObject;
@class CLXSDKConfigGeoBid;

@interface CLXSDKConfig : NSObject

@property (nonatomic, copy, nullable) NSString *appKey;
@property (nonatomic, assign) BOOL isDebug;
@property (nonatomic, copy, nullable) NSString *sessionID;
@property (nonatomic, copy, nullable) NSString *accountID;
@property (nonatomic, copy, nullable) NSArray<CLXSDKConfigBidder *> *bidders;
@property (nonatomic, copy, nullable) NSArray<CLXSDKConfigPlacement *> *placements;
@property (nonatomic, strong, nullable) CLXSDKConfigEndpointQuantumValue *auctionEndpointURL;
@property (nonatomic, strong, nullable) CLXSDKConfigEndpointObject *cdpEndpointURL;
@property (nonatomic, copy, nullable) NSString *organizationID;
@property (nonatomic, assign) NSInteger preCacheSize;
@property (nonatomic, copy, nullable) NSString *impressionTrackerURL;
@property (nonatomic, copy, nullable) NSString *metricsEndpointURL;
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
@property (nonatomic, copy, nullable) NSString *metricsEndpointURL;
@property (nonatomic, copy, nullable) NSString *sessionID;
@property (nonatomic, assign) NSInteger preCacheSize;
@property (nonatomic, strong, nullable) CLXSDKConfigEndpointQuantumValue *auctionEndpointURL;
@property (nonatomic, strong, nullable) CLXSDKConfigEndpointObject *cdpEndpointURL;
@property (nonatomic, strong, nullable) CLXSDKConfigKeyValueObject *keyValuePaths;
@property (nonatomic, copy, nullable) NSString *geoDataEndpointURL;
@property (nonatomic, strong, nullable) NSArray<CLXSDKConfigPlacement *> *placements;
@property (nonatomic, strong, nullable) NSArray<CLXSDKConfigBidder *> *bidders;
@property (nonatomic, strong, nullable) NSArray<CLXSDKConfigSeatBid *> *seatbid;
@property (nonatomic, copy, nullable) NSArray<CLXSDKConfigGeoBid *> *geoHeaders;
@property (nonatomic, copy, nullable) NSString *cur;
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *bidid;
@property (nonatomic, copy, nullable) NSString *impressionTrackerURL;
@property (nonatomic, copy, nullable) NSString *organizationID;
@property (nonatomic, copy, nullable) NSString *accountID;
@property (nonatomic, copy, nullable) NSString *appID;
@property (nonatomic, strong, nullable) NSArray<NSString *> *tracking;
@property (nonatomic, copy, nullable) NSString *winLossNotificationURL;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *winLossNotificationPayloadConfig;
@property (nonatomic, strong, nullable) CLXMetricsConfig *metricsConfig;

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

@interface CLXSDKConfigEndpointQuantumValue : NSObject
@property (nonatomic, strong, nullable) CLXSDKConfigEndpointObject *endpointObject;
@property (nonatomic, copy, nullable) NSString *endpointString;
- (instancetype)init;
- (nullable id)value;
@end

@interface CLXSDKConfigEndpointObject : NSObject
@property (nonatomic, copy, nullable) NSArray<CLXSDKConfigEndpointValue *> *test;
@property (nonatomic, copy, nullable) NSString *defaultKey;
- (instancetype)init;
@end

@interface CLXSDKConfigKeyValueObject : NSObject
@property (nonatomic, copy, nullable) NSString *appKeyValues;
@property (nonatomic, copy, nullable) NSString *eids;
@property (nonatomic, copy, nullable) NSString *placementLoopIndex;
@property (nonatomic, copy, nullable) NSString *userKeyValues;
- (instancetype)init;
@end

@interface CLXSDKConfigEndpointValue : NSObject
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) double ratio;
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

NS_ASSUME_NONNULL_END 
