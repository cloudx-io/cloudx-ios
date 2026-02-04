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
@class CLXSettings;

// Forward declarations for nested types
@class CLXBiddingConfigImpression;
@class CLXBiddingConfigApplication;
@class CLXBiddingConfigDevice;
@class CLXBiddingConfigUser;
@class CLXBiddingConfigRegulations;
@class CLXBiddingConfigRequestExt;
@class CLXBiddingConfigSource;

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
@class CLXBiddingConfigImpressionExtId;
@class CLXBiddingConfigImpressionExtSkadn;
@class CLXBiddingConfigImpressionPMPDeal;
@class CLXBiddingConfigRequestExtPrebidDebug;
@class CLXBiddingConfigRequestExtAdserverTargeting;
@class CLXBiddingConfigImpressionBannerExt;
@class CLXBiddingConfigImpressionVideoExt;
@class CLXBiddingConfigImpressionExtCloudX;
@class CLXBiddingConfigSourceExt;
@class CLXBiddingConfigSourceExtCloudX;
@class CLXBiddingConfigDeviceExtCloudX;
@class CLXBiddingConfigApplicationPublisherExtInstalledSdk;
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
@property (nonatomic, strong, nullable) NSNumber *test;
// ORTB 2.5: Source object describing the upstream supply chain
@property (nonatomic, strong, nullable) CLXBiddingConfigSource *source;

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
// NOTE: device.carrier and device.mccmnc are NOT implemented.
// CTCarrier API was deprecated in iOS 16 and returns nil/empty values in iOS 16.4+.
// These fields would never be populated on modern iOS versions.
@end

@interface CLXBiddingConfigDeviceGeo : NSObject
@property (nonatomic, strong, nullable) NSNumber *lat;
@property (nonatomic, strong, nullable) NSNumber *lon;
@property (nonatomic, strong, nullable) NSNumber *accuracy;
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSNumber *utcoffset;
// Enhanced geo fields for comprehensive location data
@property (nonatomic, copy, nullable) NSString *country;
@property (nonatomic, copy, nullable) NSString *region;
@property (nonatomic, copy, nullable) NSString *city;
@property (nonatomic, copy, nullable) NSString *zip;
@property (nonatomic, strong, nullable) NSNumber *metro;
@end

@interface CLXBiddingConfigDeviceExt : NSObject
@property (nonatomic, copy, nullable) NSString *ifv;
/// CloudX custom extension fields
@property (nonatomic, strong, nullable) CLXBiddingConfigDeviceExtCloudX *cx;
@end

/// CloudX custom device extension fields for device.ext.cx.*
@interface CLXBiddingConfigDeviceExtCloudX : NSObject
/// Redundant hardware model backup field
@property (nonatomic, copy, nullable) NSString *hw_model;
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
/// AppLovin-specific: Array of installed SDK adapter info (name, version)
@property (nonatomic, strong, nullable) NSArray<CLXBiddingConfigApplicationPublisherExtInstalledSdk *> *installed_sdk;
@end

/// Installed SDK adapter info for publisher.ext.installed_sdk
@interface CLXBiddingConfigApplicationPublisherExtInstalledSdk : NSObject
/// Adapter SDK name
@property (nonatomic, copy, nullable) NSString *id;
/// Adapter SDK version
@property (nonatomic, copy, nullable) NSString *sdk_version;
/// Adapter version
@property (nonatomic, copy, nullable) NSString *adapter_version;
@end

@interface CLXBiddingConfigApplicationPublisherPrebid : NSObject
@property (nonatomic, copy, nullable) NSString *parentAccount;
@end

// MARK: - User
@interface CLXBiddingConfigUser : NSObject
@property (nonatomic, strong, nullable) CLXBiddingConfigUserExt *ext;
/// ORTB 2.5: Gender ("M" = male, "F" = female, "O" = other). Set via KV API.
@property (nonatomic, copy, nullable) NSString *gender;
/// ORTB 2.5: Year of birth as 4-digit integer (e.g., 1990). Set via KV API.
@property (nonatomic, strong, nullable) NSNumber *yob;
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
@property (nonatomic, strong, nullable) NSNumber *atype;
@end

// MARK: - Regulations
@interface CLXBiddingConfigRegulations : NSObject
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
/// ORTB 2.5: Minimum bid price for this impression in CPM
@property (nonatomic, strong, nullable) NSNumber *bidfloor;
@property (nonatomic, copy, nullable) NSString *bidfloorcur;
@property (nonatomic, strong, nullable) NSNumber *exp;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionBanner *banner;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionVideo *video;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionNative *nativeAd;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionExt *ext;
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionPMP *pmp;
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *metric;  // Session depth metrics
/// ORTB 2.5: Name of ad mediation partner, SDK technology, or player responsible for rendering ad
@property (nonatomic, copy, nullable) NSString *displaymanager;
/// ORTB 2.5: Version of ad mediation partner, SDK technology, or player
@property (nonatomic, copy, nullable) NSString *displaymanagerver;
/// ORTB 2.5: Indicates if ad is rewarded (1 = rewarded, 0 = not rewarded)
@property (nonatomic, strong, nullable) NSNumber *rwdd;
@end

@interface CLXBiddingConfigImpressionBanner : NSObject
@property (nonatomic, strong) NSArray<CLXBiddingConfigImpressionBannerFormat *> *formats;
// ORTB 2.5: Ad position on screen (see AdPosition enum values)
@property (nonatomic, strong, nullable) NSNumber *pos;
// ORTB 2.5: Indicates if banner is in top frame (1) or iframe (0). Always 1 for native apps.
@property (nonatomic, strong, nullable) NSNumber *topframe;
/// ORTB 2.5: Banner width at root level (in addition to format array)
@property (nonatomic, strong, nullable) NSNumber *w;
/// ORTB 2.5: Banner height at root level (in addition to format array)
@property (nonatomic, strong, nullable) NSNumber *h;
/// ORTB 2.5: Unique identifier for this banner object. Standard convention is "1" for single banner per impression.
@property (nonatomic, copy, nullable) NSString *bannerId;
/// Extension object for banner-specific extensions
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionBannerExt *ext;
@end

/// Banner extension object for banner.ext.*
@interface CLXBiddingConfigImpressionBannerExt : NSObject
/// AppLovin-specific: Banner type ("rewarded" for rewarded ads)
@property (nonatomic, copy, nullable) NSString *bannertype;
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
/// ORTB 2.5: Minimum video ad duration in seconds (server-driven)
@property (nonatomic, strong, nullable) NSNumber *minduration;
/// ORTB 2.5: Maximum video ad duration in seconds (server-driven)
@property (nonatomic, strong, nullable) NSNumber *maxduration;
/// ORTB 2.5: Video start delay in seconds (server-driven)
@property (nonatomic, strong, nullable) NSNumber *startdelay;
/// ORTB 2.5: Indicates if the video is skippable (1 = skippable, 0 = not skippable)
@property (nonatomic, strong, nullable) NSNumber *skip;
/// ORTB 2.5: Minimum duration in seconds before skip button appears (server-driven)
@property (nonatomic, strong, nullable) NSNumber *skipmin;
/// ORTB 2.5: Number of seconds into video when skip button appears (server-driven)
@property (nonatomic, strong, nullable) NSNumber *skipafter;
/// ORTB 2.5: Playback methods supported (server-driven)
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *playbackmethod;
/// Extension object for video-specific extensions
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionVideoExt *ext;
@end

/// Video extension object for video.ext.*
@interface CLXBiddingConfigImpressionVideoExt : NSObject
/// AppLovin-specific: Video type ("rewarded" for rewarded ads)
@property (nonatomic, copy, nullable) NSString *videotype;
@end

@interface CLXBiddingConfigImpressionNative : NSObject
@property (nonatomic, copy) NSString *ver;
@property (nonatomic, copy) NSString *request;
@end

@interface CLXBiddingConfigImpressionExt : NSObject
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionExtStoredImpression *prebid;
@property (nonatomic, strong, nullable) NSDictionary *bidder;
@property (nonatomic, strong, nullable) NSDictionary *data;
/// SKAdNetwork object for iOS attribution (OpenRTB 2.6 / IAB SKAN spec)
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionExtSkadn *skadn;
/// CloudX custom extension fields for imp.ext.cx.*
@property (nonatomic, strong, nullable) CLXBiddingConfigImpressionExtCloudX *cx;
@end

/// CloudX custom impression extension fields for imp.ext.cx.*
@interface CLXBiddingConfigImpressionExtCloudX : NSObject
/// Session depth (number of ads shown in this session)
@property (nonatomic, strong, nullable) NSNumber *depth;
/// Ad format string ("banner", "mrec", "interstitial", "rewarded", "native")
@property (nonatomic, copy, nullable) NSString *format;
/// Session UUID for this app session
@property (nonatomic, copy, nullable) NSString *sess_id;
/// Session time in milliseconds
@property (nonatomic, strong, nullable) NSNumber *sess_time;
/// Ad Unit ID from publisher configuration
@property (nonatomic, copy, nullable) NSString *ad_unit_id;
@end

/// SKAdNetwork request object per IAB SKAN spec
/// Tells bidders which SKAN versions are supported and which network IDs are in the publisher's plist
@interface CLXBiddingConfigImpressionExtSkadn : NSObject
/// Highest SKAN version supported by the device (e.g., "4.0")
@property (nonatomic, copy, nullable) NSString *version;
/// All SKAN versions supported by the device (e.g., ["2.0", "2.1", "2.2", "3.0", "4.0"])
@property (nonatomic, strong, nullable) NSArray<NSString *> *versions;
/// Publisher app's bundle identifier (source of the ad impression)
@property (nonatomic, copy, nullable) NSString *sourceapp;
/// Array of SKAdNetwork IDs from the publisher's Info.plist that bidders can use for attribution
@property (nonatomic, strong, nullable) NSArray<NSString *> *skadnetids;
@end

@interface CLXBiddingConfigImpressionExtStoredImpression : NSObject
@property (nonatomic, strong) CLXBiddingConfigImpressionExtId *storedimpression;
@property (nonatomic, strong, nullable) NSDictionary *bidder;
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

// MARK: - Source (ORTB 2.5)
@interface CLXBiddingConfigSource : NSObject
// ORTB 2.5: Entity responsible for the final impression sale decision (integer: 1 = exchange)
@property (nonatomic, strong, nullable) NSNumber *fd;
// ORTB 2.5: Transaction ID for this bid request
@property (nonatomic, copy, nullable) NSString *tid;
// ORTB 2.5: Payment ID chain string (ads.txt/sellers.json)
@property (nonatomic, copy, nullable) NSString *pchain;
/// Extension object for source-specific extensions
@property (nonatomic, strong, nullable) CLXBiddingConfigSourceExt *ext;
@end

/// Source extension object for source.ext.*
@interface CLXBiddingConfigSourceExt : NSObject
/// CloudX custom extension fields for source.ext.cx.*
@property (nonatomic, strong, nullable) CLXBiddingConfigSourceExtCloudX *cx;
@end

/// CloudX custom source extension fields for source.ext.cx.*
@interface CLXBiddingConfigSourceExtCloudX : NSObject
/// Persistent install UUID (generated once, stored in UserDefaults)
@property (nonatomic, copy, nullable) NSString *install_id;
@end

// MARK: - Response classes removed
// Use CLXBidResponse, CLXBidResponseBid, etc. from CLXBidResponse.h instead

NS_ASSUME_NONNULL_END 
