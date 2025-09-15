//
//  BiddingConfig.h
//  CloudXCore
//
//  Created by Migration Tool.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXConfigImpressionModel.h>

@class CLXPrivacyService;

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAdRequirements;
@class CLXSKAdRequestParameters;
@class CLXReachabilityService;
@class CLXTimeService;
@class CLXSystemInformation;
@class CLXCloudXPrivacy;
@class CLXAppSessionModel;
@class CLXSettings;

// Forward declarations for nested types
@class CLXBiddingConfigImpression;
@class CLXBiddingConfigApplication;
@class CLXBiddingConfigDevice;
@class CLXBiddingConfigUser;
@class CLXBiddingConfigRegulations;
@class CLXBiddingConfigRequestExt;

// Forward declarations for nested classes
@class CLXBiddingConfigDeviceGeo;
@class CLXBiddingConfigDeviceExt;
@class CLXBiddingConfigApplicationPublisher;
@class CLXBiddingConfigApplicationPublisherExt;
@class CLXBiddingConfigApplicationPublisherPrebid;
@class CLXBiddingConfigUserExt;
@class CLXBiddingConfigUserExtEids;
@class CLXBiddingConfigUserExtUids;
@class CLXBiddingConfigApplicationExt;
@class CLXBiddingConfigRegulationsExt;
@class CLXBiddingConfigRegulationsExtIAB;
@class CLXBiddingConfigImpressionBanner;
@class CLXBiddingConfigImpressionVideo;
@class CLXBiddingConfigImpressionNative;
@class CLXBiddingConfigImpressionExt;
//@class CLXBiddingConfigImpressionExtData;
@class CLXBiddingConfigImpressionPMP;
@class CLXBiddingConfigImpressionBannerFormat;
@class CLXBiddingConfigImpressionExtStoredImpression;
@class CLXBiddingConfigImpressionExtAdserverTargeting;
@class CLXBiddingConfigImpressionExtId;
@class CLXBiddingConfigImpressionPMPDeal;
@class CLXBiddingConfigRequestExtPrebidDebug;
@class CLXBiddingConfigRequestExtAdserverTargeting;
// Response classes removed - use CLXBidResponse.h instead

// MARK: - BiddingConfig
@interface CLXBiddingConfig : NSObject
@end

// MARK: - BiddingConfigRequest
@interface CLXBiddingConfigRequest : NSObject
@property (nonatomic, assign) CLXAdType adType;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, copy) NSString *storedImpressionId;
@property (nonatomic, copy, nullable) NSString *dealID;
@property (nonatomic, strong, nullable) NSNumber *bidFloor;
@property (nonatomic, copy) NSString *displayManager;
@property (nonatomic, copy) NSString *displayManagerVer;
@property (nonatomic, copy) NSString *publisherID;
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, copy, nullable) NSString *userAgent;
@property (nonatomic, strong) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *adapterInfo;
@property (nonatomic, strong, nullable) CLXNativeAdRequirements *nativeAdRequirements;
@property (nonatomic, strong, nullable) CLXSKAdRequestParameters *skadRequestParameters;
@property (nonatomic, strong, nullable) NSNumber *tmax;

// Nested objects
@property (nonatomic, strong) NSArray<CLXBiddingConfigImpression *> *impressions;
@property (nonatomic, strong) CLXBiddingConfigApplication *application;
@property (nonatomic, strong) CLXBiddingConfigDevice *device;
@property (nonatomic, strong) CLXBiddingConfigUser *user;
@property (nonatomic, strong) CLXBiddingConfigRegulations *regulations;
@property (nonatomic, strong) CLXBiddingConfigRequestExt *ext;
@property (nonatomic, copy) NSString *requestID;

- (instancetype)initWithAdType:(CLXAdType)adType
                     adUnitID:(NSString *)adUnitID
            storedImpressionId:(NSString *)storedImpressionId
                        dealID:(NSString *)dealID
                     bidFloor:(NSNumber *)bidFloor
                displayManager:(NSString *)displayManager
            displayManagerVer:(NSString *)displayManagerVer
                   publisherID:(NSString *)publisherID
                      location:(CLLocation *)location
                     userAgent:(NSString *)userAgent
                   adapterInfo:(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)adapterInfo
           nativeAdRequirements:(id)nativeAdRequirements
           skadRequestParameters:(id)skadRequestParameters
                          tmax:(NSNumber *)tmax
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                      settings:(CLXSettings *)settings
                privacyService:(CLXPrivacyService *)privacyService;

/**
 * Converts the bid request to a JSON dictionary for network transmission
 * This matches the Swift SDK's RequestParameters.json property
 */
- (NSDictionary *)json;

@end

// MARK: - Device
@interface CLXBiddingConfigDevice : NSObject
@property (nonatomic, copy) NSString *ua;
@property (nonatomic, copy) NSString *make;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *os;
@property (nonatomic, copy) NSString *osv;
@property (nonatomic, copy) NSString *hwv;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, strong) NSNumber *dnt;
@property (nonatomic, strong) NSNumber *devicetype;
@property (nonatomic, strong) NSNumber *h;
@property (nonatomic, strong) NSNumber *w;
@property (nonatomic, strong) NSNumber *ppi;
@property (nonatomic, strong) NSNumber *connectiontype;
@property (nonatomic, strong, nullable) NSNumber *lmt;
@property (nonatomic, strong) NSNumber *pxratio;
@property (nonatomic, strong) CLXBiddingConfigDeviceGeo *geo;
@property (nonatomic, strong) CLXBiddingConfigDeviceExt *ext;
@end

@interface CLXBiddingConfigDeviceGeo : NSObject
@property (nonatomic, strong, nullable) NSNumber *lat;
@property (nonatomic, strong, nullable) NSNumber *lon;
@property (nonatomic, strong, nullable) NSNumber *accuracy;
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSNumber *utcoffset;
@end

@interface CLXBiddingConfigDeviceExt : NSObject
@property (nonatomic, copy, nullable) NSString *ifv;
@end

// MARK: - Application
@interface CLXBiddingConfigApplication : NSObject
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *bundle;
@property (nonatomic, copy) NSString *ver;
@property (nonatomic, strong) CLXBiddingConfigApplicationPublisher *publisher;
@property (nonatomic, strong) CLXBiddingConfigApplicationExt *ext;
@end

@interface CLXBiddingConfigApplicationExt : NSObject
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *data;
@end

@interface CLXBiddingConfigApplicationPublisher : NSObject
@property (nonatomic, copy) NSString *publisherID;
@property (nonatomic, strong) CLXBiddingConfigApplicationPublisherExt *ext;
@end

@interface CLXBiddingConfigApplicationPublisherExt : NSObject
@property (nonatomic, strong) CLXBiddingConfigApplicationPublisherPrebid *prebid;
@end

@interface CLXBiddingConfigApplicationPublisherPrebid : NSObject
@property (nonatomic, copy, nullable) NSString *parentAccount;
@end

// MARK: - User
@interface CLXBiddingConfigUser : NSObject
@property (nonatomic, copy, nullable) NSString *keywords;
@property (nonatomic, strong, nullable) CLXBiddingConfigUserExt *ext;
@end

@interface CLXBiddingConfigUserExt : NSObject
//@property (nonatomic, copy) NSString *consent;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *data;
@property (nonatomic, strong) NSArray<CLXBiddingConfigUserExtEids *> *eids;

@end

@interface CLXBiddingConfigUserExtEids : NSObject
@property (nonatomic, copy, nullable) NSString *source;
@property (nonatomic, strong) NSArray<CLXBiddingConfigUserExtUids *> *uids;
@end

@interface CLXBiddingConfigUserExtUids : NSObject
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *atype;
@end

// MARK: - Regulations
@interface CLXBiddingConfigRegulations : NSObject
@property (nonatomic, strong, nullable) NSNumber *coppa;
@property (nonatomic, strong, nullable) CLXBiddingConfigRegulationsExt *ext;
@end

@interface CLXBiddingConfigRegulationsExt : NSObject
@property (nonatomic, strong, nullable) CLXBiddingConfigRegulationsExtIAB *iab;
@property (nonatomic, strong, nullable) NSNumber *gdpr;
@property (nonatomic, strong, nullable) NSNumber *ccpa;
@property (nonatomic, copy, nullable) NSString *gpp;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *gppSid;
@end

@interface CLXBiddingConfigRegulationsExtIAB : NSObject
@property (nonatomic, strong, nullable) NSNumber *gdprApplies;
@property (nonatomic, copy, nullable) NSString *tcString;
@property (nonatomic, copy, nullable) NSString *usPrivacyString;
@end

// MARK: - Impression
@interface CLXBiddingConfigImpression : NSObject
@property (nonatomic, copy) NSString *impressionID;
@property (nonatomic, copy) NSString *tagid;
@property (nonatomic, strong) NSNumber *instl;
@property (nonatomic, copy, nullable) NSString *bidfloorcur;
@property (nonatomic, strong, nullable) NSNumber *exp;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionBanner *banner;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionVideo *video;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionNative *nativeAd;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionExt *ext;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionPMP *pmp;
@end

@interface CLXBiddingConfigImpressionBanner : NSObject
@property (nonatomic, strong) NSArray<CLXBiddingConfigImpressionBannerFormat *> *formats;
@end

@interface CLXBiddingConfigImpressionBannerFormat : NSObject
@property (nonatomic, strong) NSNumber *w;
@property (nonatomic, strong) NSNumber *h;
@end

@interface CLXBiddingConfigImpressionVideo : NSObject
@property (nonatomic, strong) NSNumber *w;
@property (nonatomic, strong) NSNumber *h;
@property (nonatomic, strong) NSArray<NSString *> *mimes;
@property (nonatomic, strong) NSArray<NSNumber *> *protocols;
@property (nonatomic, strong) NSArray<NSNumber *> *api;
@property (nonatomic, strong) NSNumber *placement;
@property (nonatomic, strong) NSNumber *linearity;
@property (nonatomic, strong) NSNumber *pos;
@property (nonatomic, strong) NSArray<NSNumber *> *companiontype;
@end

@interface CLXBiddingConfigImpressionNative : NSObject
@property (nonatomic, copy) NSString *ver;
@property (nonatomic, copy) NSString *request;
@end

@interface CLXBiddingConfigImpressionExt : NSObject
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionExtStoredImpression *prebid;
@property (nonatomic, strong, nullable) NSDictionary *bidder;
@property (nonatomic, strong, nullable) NSDictionary *data;
@end

//@interface CLXBiddingConfigImpressionExtData : NSObject
//@property (nonatomic, copy) NSString *loopIndex;
//@end

@interface CLXBiddingConfigImpressionExtStoredImpression : NSObject
@property (nonatomic, strong) NSArray<CLXBiddingConfigImpressionExtAdserverTargeting *> *adservertargeting;
@property (nonatomic, strong) CLXBiddingConfigImpressionExtId *storedimpression;
@property (nonatomic, strong, nullable) NSDictionary *bidder;
@end

@interface CLXBiddingConfigImpressionExtAdserverTargeting : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *value;
@end

@interface CLXBiddingConfigImpressionExtId : NSObject
@property (nonatomic, copy) NSString *idValue;
@end

@interface CLXBiddingConfigImpressionPMP : NSObject
@property (nonatomic, strong) NSArray<CLXBiddingConfigImpressionPMPDeal *> *deals;
@end

@interface CLXBiddingConfigImpressionPMPDeal : NSObject
@property (nonatomic, copy) NSString *dealID;
@end

// MARK: - RequestExt
@interface CLXBiddingConfigRequestExt : NSObject
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *adapterExtras;
@property (nonatomic, strong, nullable) CLXBiddingConfigRequestExtPrebidDebug *prebid;
@end

@interface CLXBiddingConfigRequestExtPrebidDebug : NSObject
@property (nonatomic, strong) NSNumber *debug;
@property (nonatomic, strong) NSArray<CLXBiddingConfigRequestExtAdserverTargeting *> *adservertargeting;
@end

@interface CLXBiddingConfigRequestExtAdserverTargeting : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *value;
@end

// MARK: - Response classes removed
// Use CLXBidResponse, CLXBidResponseBid, etc. from CLXBidResponse.h instead

NS_ASSUME_NONNULL_END 
