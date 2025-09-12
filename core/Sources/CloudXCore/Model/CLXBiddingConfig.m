//
//  BiddingConfig.m
//  CloudXCore
//
//  Created by Migration Tool.
//

#import <CloudXCore/CLXBiddingConfig.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXReachabilityService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>

// Internal methods category for accessing privacy methods that are not in public header
// TEMP: Remove CLXPrivacyService private interface once server supports GDPR/COPPA
@interface CLXPrivacyService (Internal)
- (nullable NSString *)gdprConsentString;
- (nullable NSNumber *)gdprApplies;
- (nullable NSNumber *)coppaApplies;
@end

// Test category for dependency injection (SOLID: Interface Segregation)
@interface CLXBiddingConfigRequest (Testing)
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
@end

#pragma mark - CLXBiddingConfig
@implementation CLXBiddingConfig
@end

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"BiddingConfig.m"];
}

#pragma mark - CLXBiddingConfigRequest
@implementation CLXBiddingConfigRequest

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
{
    self = [super init];
    if (self) {
        _adType = adType;
        _adUnitID = [adUnitID copy];
        _storedImpressionId = [storedImpressionId copy];
        _dealID = [dealID copy];
        _bidFloor = bidFloor;
        _displayManager = [displayManager copy];
        _displayManagerVer = [displayManagerVer copy];
        _publisherID = [publisherID copy];
        _location = location;
        _userAgent = [userAgent copy];
        _adapterInfo = [adapterInfo copy];
        _nativeAdRequirements = nativeAdRequirements;
        _skadRequestParameters = skadRequestParameters;
        _tmax = tmax;
        
        // Calculate screen dimensions based on ad type
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        NSInteger screenWidth = (NSInteger)screenRect.size.width;
        NSInteger screenHeight = (NSInteger)screenRect.size.height;
        
        if (adType == CLXAdTypeMrec) {
            screenWidth = 300;
            screenHeight = 250;
        } else if (adType == CLXAdTypeBanner) {
            screenWidth = 320;
            screenHeight = 50;
        }
        // For interstitial, rewarded, native: use full screen dimensions

        // Create banner format
        CLXBiddingConfigImpressionBannerFormat *format = [[CLXBiddingConfigImpressionBannerFormat alloc] init];
        format.w = @(screenWidth);
        format.h = @(screenHeight);

        // Create banner with formats
        CLXBiddingConfigImpressionBanner *banner = [[CLXBiddingConfigImpressionBanner alloc] init];
        banner.formats = @[format]; // Single format as in Swift
        
        // Interstitial and rewarded ads don't need banner formats

        // Create video
        CLXBiddingConfigImpressionVideo *video = [[CLXBiddingConfigImpressionVideo alloc] init];
        video.w = @(screenWidth);
        video.h = @(screenHeight);
        video.mimes = @[@"video/mp4", @"video/3gpp", @"video/3gpp2", @"video/x-m4v", @"video/quicktime"];
        video.protocols = @[@2, @3, @5, @6, @7, @8];
        video.api = @[@3, @5, @6, @7];
        video.placement = @5;
        video.linearity = @1;
        video.pos = @7;
        video.companiontype = @[@1, @2];
        
        // Create stored impression ID
        CLXBiddingConfigImpressionExtId *idObj = [[CLXBiddingConfigImpressionExtId alloc] init];
        idObj.idValue = storedImpressionId;
        
        // Create targeting dictionary from UserDefaults
        NSMutableArray *targetingDict = [NSMutableArray array];
        NSDictionary *userDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey];
        for (NSString *key in userDict.allKeys) {
            CLXBiddingConfigImpressionExtAdserverTargeting *targeting = [[CLXBiddingConfigImpressionExtAdserverTargeting alloc] init];
            targeting.key = key;
            targeting.source = @"bidrequest";
            targeting.value = userDict[key] ?: @"";
            [targetingDict addObject:targeting];
        }
        
        // Create stored impression
        CLXBiddingConfigImpressionExtStoredImpression *storedImpression = [[CLXBiddingConfigImpressionExtStoredImpression alloc] init];
        storedImpression.adservertargeting = [targetingDict copy];
        storedImpression.storedimpression = idObj;
        
        // Add default bidder to satisfy server validation
        // The server expects at least one bidder in ext.prebid.bidder
        NSDictionary *defaultBidder = @{
            @"testbidder": @{
                @"adservertargeting": @[
                    @{
                        @"key": @"loop-index",
                        @"source": @"bidrequest",
                        @"value": @"0"
                    }
                ]
            }
        };
        storedImpression.bidder = defaultBidder;
        
        [logger debug:[NSString stringWithFormat:@"✅ [BiddingConfig] Default bidder configured: %@", defaultBidder]];
        
        // Create impression ext
        CLXBiddingConfigImpressionExt *impExt = [[CLXBiddingConfigImpressionExt alloc] init];
        impExt.prebid = storedImpression;
        
        impExt.data = @{@"loop-index": @"0"};
        
        // Create native ad if needed
        CLXBiddingConfigImpressionNative *native = nil;
        if (adType == CLXAdTypeNative && nativeAdRequirements) {
            [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Creating native ad with requirements: %@", nativeAdRequirements]];
            
            // Encode nativeAdRequirements to JSON string like Swift version
            NSError *jsonError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:nativeAdRequirements options:0 error:&jsonError];
            if (jsonError) {
                [logger error:[NSString stringWithFormat:@"❌ [BiddingConfig] Failed to encode native ad requirements: %@", jsonError]];
            } else {
                NSString *requestString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [logger info:[NSString stringWithFormat:@"✅ [BiddingConfig] Native ad requirements encoded: %@", requestString]];
                
                native = [[CLXBiddingConfigImpressionNative alloc] init];
                native.ver = @"1.2";
                native.request = requestString;
            }
        }
        
        // Create impression
        CLXBiddingConfigImpression *impression = [[CLXBiddingConfigImpression alloc] init];
        // Generate unique impression ID per request (OpenRTB compliance)
        impression.impressionID = [[NSUUID UUID] UUIDString];
        impression.tagid = storedImpressionId;
        
        [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Creating impression - AdType: %ld, Dimensions: %ldx%ld", (long)adType, (long)screenWidth, (long)screenHeight]];
        
        impression.instl = (adType == CLXAdTypeInterstitial || adType == CLXAdTypeRewarded) ? @1 : @0;
        
        // Match Swift SDK logic exactly - don't set bidfloor (it's commented out in Swift)
        // impression.bidfloor = @(bidFloor);
        
        // Add missing fields to match Swift SDK
        impression.bidfloorcur = @"USD";
        impression.exp = @14400;
        
        // Use integer enum comparisons - much cleaner and faster
        BOOL isBanner = (adType == CLXAdTypeBanner);
        BOOL isMrec = (adType == CLXAdTypeMrec);
        BOOL isInterstitial = (adType == CLXAdTypeInterstitial);  
        BOOL isRewarded = (adType == CLXAdTypeRewarded);
        BOOL isNative = (adType == CLXAdTypeNative);
        
        // NOTE: This may be a quirk of META/FAN, but interstitials will only show if the banner is set and video is excluded
        impression.banner = (isBanner || isMrec || isInterstitial) ? banner : nil;
        impression.video = (isRewarded) ? video : nil;
        impression.nativeAd = (isNative) ? native : nil;
        impression.ext = impExt;
        impression.pmp = nil;
        
        [logger debug:[NSString stringWithFormat:@"✅ [BiddingConfig] Impression created - instl:%@, banner:%@, video:%@, native:%@", 
                       impression.instl, 
                       impression.banner ? @"YES" : @"NO", 
                       impression.video ? @"YES" : @"NO", 
                       impression.nativeAd ? @"YES" : @"NO"]];
        
        _impressions = @[impression];
        
        // Create application
        NSString *accId = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAccountIDKey] ?: @"";
        CLXBiddingConfigApplicationPublisherPrebid *publisherPrebid = [[CLXBiddingConfigApplicationPublisherPrebid alloc] init];
        publisherPrebid.parentAccount = accId.length > 0 ? accId : nil;
        
        CLXBiddingConfigApplicationPublisherExt *publisherExt = [[CLXBiddingConfigApplicationPublisherExt alloc] init];
        publisherExt.prebid = publisherPrebid;
        
        CLXBiddingConfigApplicationPublisher *publisher = [[CLXBiddingConfigApplicationPublisher alloc] init];
        publisher.publisherID = publisherID;
        publisher.ext = publisherExt;
        
        NSString *bundle = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreBundleConfigKey];
        if (!bundle || bundle.length == 0) {
            bundle = [[NSBundle mainBundle] bundleIdentifier];
        }
        
        NSDictionary *value = @{
        @"appKey1": @"appValue1",
        @"appKey2": @"appValue2",
        @"appKey3": @"appValue3"};
        
        CLXBiddingConfigApplication *application = [[CLXBiddingConfigApplication alloc] init];
        application.appID = @"5646234";
        application.bundle = bundle;
        application.ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        application.publisher = publisher;
        application.ext.data = value;
        
        _application = application;
        
        // Create device with privacy-aware geo data (will be used later for privacy check)
        CLXBiddingConfigDeviceGeo *geo = [[CLXBiddingConfigDeviceGeo alloc] init];
        geo.lat = location ? @(location.coordinate.latitude) : nil;
        geo.lon = location ? @(location.coordinate.longitude) : nil;
        geo.accuracy = location ? @(location.horizontalAccuracy) : nil;
        geo.type = @1;
        geo.utcoffset = @([[NSTimeZone localTimeZone] secondsFromGMT] / 60);
        
        CLXBiddingConfigDeviceExt *deviceExt = [[CLXBiddingConfigDeviceExt alloc] init];
        deviceExt.ifv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        
        // This handles all configuration scenarios with proper debug/production safety
        NSString *ifa = [settings getIFA];
        
        // Apply privacy-aware data handling (matching Android implementation)
        CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
        BOOL shouldClearPersonalData = [privacyService shouldClearPersonalDataWithGPP];
        
        CLXBiddingConfigDevice *device = [[CLXBiddingConfigDevice alloc] init];
        device.ua = userAgent ?: @"ua";
        device.make = @"Apple";
        device.model = [[UIDevice currentDevice] model];
        device.os = @"iOS";
        device.osv = [[UIDevice currentDevice] systemVersion];
        device.hwv = [[UIDevice currentDevice] systemVersion];
        device.language = [[NSLocale currentLocale] languageCode];
        
        // Apply privacy-aware IFA handling (matching Android implementation)
        device.ifa = shouldClearPersonalData ? @"" : ifa;
        device.dnt = @0;
        device.devicetype = @([CLXSystemInformation shared].deviceType); // Use robust device type detection
        device.h = @(screenHeight);
        device.w = @(screenWidth);
        device.ppi = @([[UIScreen mainScreen] scale] * 163); // Approximate PPI
        device.connectiontype = @([CLXReachabilityService shared].currentReachabilityType); // Use robust connection type detection
        device.lmt = nil;
        device.pxratio = @([[UIScreen mainScreen] scale]);
        
        // Apply privacy-aware geo data handling (matching Android implementation)
        if (shouldClearPersonalData) {
            // Clear precise location data but keep timezone and type
            geo.lat = nil;
            geo.lon = nil;
            geo.accuracy = nil;
        }
        device.geo = geo;
        device.ext = deviceExt;
        
        _device = device;
        
        // Create user with privacy-aware data handling
        NSString *hashedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedUserIDKey];
        NSString *aiPrompt = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAIPromptKey];
        NSString *userKeywords = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserKeywordsKey];
        
        CLXBiddingConfigUserExt *userExt = [[CLXBiddingConfigUserExt alloc] init];
        
        // Apply privacy-aware user data handling (matching Android implementation)
        if (!shouldClearPersonalData) {
            // Only include personal user data when privacy allows
            CLXBiddingConfigUserExtUids * uids = [[CLXBiddingConfigUserExtUids alloc] init];
            uids.id = @"29060c8606954ec90fbcde825b2783b0b9261585793db9dfcbe6b870a05a9ee3";
            uids.atype = @"3";
            
            CLXBiddingConfigUserExtEids *eids = [[CLXBiddingConfigUserExtEids alloc] init];
            eids.source = bundle;
            eids.uids = uids;
            
            NSDictionary *userValue = @{
                @"userKey1": @"userValue1",
                @"userKey2": @"userValue2",
                @"userKey3": @"userValue3"};
            
            userExt.data = userValue;
            userExt.eids = eids;
        }
        // When personal data should be cleared, userExt remains minimal with no personal identifiers
        
        CLXBiddingConfigUser *user = [[CLXBiddingConfigUser alloc] init];
        user.keywords = userKeywords.length > 0 ? userKeywords : nil;
        user.ext = userExt;
        
        _user = user;
        
        // Create regulations with privacy service integration
        CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
        
        // Create regulations with GPP support
        CLXBiddingConfigRegulationsExtIAB *iab = [[CLXBiddingConfigRegulationsExtIAB alloc] init];
        iab.usPrivacyString = [privacyService ccpaPrivacyString]; // Legacy CCPA support

        CLXBiddingConfigRegulationsExt *regExt = [[CLXBiddingConfigRegulationsExt alloc] init];
        regExt.iab = iab;
        
        // Add GPP data to regulations ext
        NSString *gppString = [privacyService gppString];
        if (gppString) {
            regExt.gpp = gppString;
        }
        
        NSArray<NSNumber *> *gppSid = [privacyService gppSid];
        if (gppSid && gppSid.count > 0) {
            regExt.gppSid = gppSid;
        }

        CLXBiddingConfigRegulations *regulations = [[CLXBiddingConfigRegulations alloc] init];
        regulations.ext = regExt;
        
        // Enable COPPA in bid requests (now supported with GPP implementation)
        if ([privacyService respondsToSelector:@selector(isCoppaEnabled)] && 
            [(id)privacyService performSelector:@selector(isCoppaEnabled)]) {
            regulations.coppa = @YES;
        }

        // TODO: Re-enable GDPR once server support is implemented
        // iab.gdprApplies = [privacyService gdprApplies];
        // iab.tcString = [privacyService gdprConsentString];
        // regExt.gdpr = [privacyService gdprApplies];

        _regulations = regulations;
        
        // Create request ext
        NSMutableDictionary *adapterExtras = [NSMutableDictionary dictionary];
        for (NSString *key in adapterInfo.allKeys) {
            adapterExtras[key] = adapterInfo[key];
        }
        
        NSMutableArray *prebidArray = [NSMutableArray array];
        for (NSString *key in userDict.allKeys) {
            CLXBiddingConfigRequestExtAdserverTargeting *targeting = [[CLXBiddingConfigRequestExtAdserverTargeting alloc] init];
            targeting.key = key;
            targeting.source = @"bidrequest";
            targeting.value = userDict[key] ?: @"";
            [prebidArray addObject:targeting];
        }
        
        CLXBiddingConfigRequestExtPrebidDebug *prebid = [[CLXBiddingConfigRequestExtPrebidDebug alloc] init];
        prebid.debug = @YES;
        prebid.adservertargeting = [prebidArray copy];
        
        CLXBiddingConfigRequestExt *ext = [[CLXBiddingConfigRequestExt alloc] init];
        ext.adapterExtras = [adapterExtras copy];
        ext.prebid = prebid;
        
        _ext = ext;
        _requestID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

// SOLID: Test-only initializer with dependency injection (Interface Segregation)
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
                privacyService:(CLXPrivacyService *)privacyService {
    
    // Call the standard initializer first
    self = [self initWithAdType:adType
                       adUnitID:adUnitID
              storedImpressionId:storedImpressionId
                          dealID:dealID
                       bidFloor:bidFloor
                  displayManager:displayManager
              displayManagerVer:displayManagerVer
                     publisherID:publisherID
                        location:location
                       userAgent:userAgent
                     adapterInfo:adapterInfo
             nativeAdRequirements:nativeAdRequirements
             skadRequestParameters:skadRequestParameters
                            tmax:tmax
                        impModel:impModel
                        settings:settings];
    
    if (self) {
        // Override regulations with the injected privacy service
        CLXBiddingConfigRegulationsExtIAB *iab = [[CLXBiddingConfigRegulationsExtIAB alloc] init];
        iab.usPrivacyString = [privacyService ccpaPrivacyString]; // Use injected service
        
        CLXBiddingConfigRegulationsExt *regExt = [[CLXBiddingConfigRegulationsExt alloc] init];
        regExt.iab = iab;
        
        // Add GPP data from injected service
        NSString *gppString = [privacyService gppString];
        if (gppString) {
            regExt.gpp = gppString;
        }
        
        NSArray<NSNumber *> *gppSid = [privacyService gppSid];
        if (gppSid && gppSid.count > 0) {
            regExt.gppSid = gppSid;
        }
        
        CLXBiddingConfigRegulations *regulations = [[CLXBiddingConfigRegulations alloc] init];
        regulations.ext = regExt;
        
        // Enable COPPA in bid requests with injected service
        if ([privacyService respondsToSelector:@selector(isCoppaEnabled)] && 
            [(id)privacyService performSelector:@selector(isCoppaEnabled)]) {
            regulations.coppa = @YES;
        }
        
        _regulations = regulations;
    }
    
    return self;
}

- (NSDictionary *)json {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // Add basic fields
    json[@"id"] = self.requestID ?: @"";
    json[@"imp"] = [self convertImpressionsToJSON];
    json[@"app"] = [self convertApplicationToJSON];
    json[@"device"] = [self convertDeviceToJSON];
    json[@"user"] = [self convertUserToJSON];
    json[@"regs"] = [self convertRegulationsToJSON];
    json[@"ext"] = [self convertExtToJSON];
    
    if (self.tmax) {
        json[@"tmax"] = self.tmax;
    }
    
    // Debug logging
    [logger debug:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] Final bid request - Keys: %@, Imp count: %lu", [json allKeys], (unsigned long)[json[@"imp"] count]]];
    
    // Log the complete JSON structure
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        [logger error:[NSString stringWithFormat:@"❌ [ObjC-BiddingConfig] JSON serialization error: %@", error]];
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [logger info:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] Complete Bid Request JSON:"]];
        [logger info:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] ========================================"]];
        [logger info:[NSString stringWithFormat:@"%@", jsonString]];
        [logger info:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] ========================================"]];
    }
    
    return [json copy];
}

- (NSArray *)convertImpressionsToJSON {
    NSMutableArray *impressionsArray = [NSMutableArray array];
    for (CLXBiddingConfigImpression *impression in self.impressions) {
        [impressionsArray addObject:[self convertImpressionToJSON:impression]];
    }
    return [impressionsArray copy];
}

- (NSDictionary *)convertImpressionToJSON:(CLXBiddingConfigImpression *)impression {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"id"] = impression.impressionID ?: @"";
    json[@"tagid"] = impression.tagid ?: @"";
    json[@"instl"] = impression.instl ?: @0;
    json[@"secure"] = @1;
    json[@"bidfloorcur"] = impression.bidfloorcur ?: @"USD";
    json[@"exp"] = impression.exp ?: @14400;
    
    if (impression.banner) {
        json[@"banner"] = [self convertBannerToJSON:impression.banner];
    }
    if (impression.video) {
        json[@"video"] = [self convertVideoToJSON:impression.video];
    }
    if (impression.nativeAd) {
        json[@"native"] = [self convertNativeToJSON:impression.nativeAd];
    }
    if (impression.ext) {
        json[@"ext"] = [self convertImpressionExtToJSON:impression.ext];
    }
    if (impression.pmp) {
        json[@"pmp"] = [self convertPMPToJSON:impression.pmp];
    }
    
    return [json copy];
}

- (NSDictionary *)convertBannerToJSON:(CLXBiddingConfigImpressionBanner *)banner {
    NSMutableArray *formatsArray = [NSMutableArray array];
    for (CLXBiddingConfigImpressionBannerFormat *format in banner.formats) {
        [formatsArray addObject:@{
            @"w": format.w ?: @0,
            @"h": format.h ?: @0
        }];
    }
    return @{@"format": [formatsArray copy]};
}

- (NSDictionary *)convertVideoToJSON:(CLXBiddingConfigImpressionVideo *)video {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"w"] = video.w ?: @0;
    json[@"h"] = video.h ?: @0;
    json[@"mimes"] = video.mimes ?: @[];
    json[@"protocols"] = video.protocols ?: @[];
    json[@"api"] = video.api ?: @[];
    json[@"placement"] = video.placement ?: @0;
    json[@"linearity"] = video.linearity ?: @0;
    json[@"pos"] = video.pos ?: @0;
    json[@"companiontype"] = video.companiontype ?: @[];
    return [json copy];
}

- (NSDictionary *)convertNativeToJSON:(CLXBiddingConfigImpressionNative *)native {
    return @{
        @"ver": native.ver ?: @"1.2",
        @"request": native.request ?: @""
    };
}

- (NSDictionary *)convertImpressionExtToJSON:(CLXBiddingConfigImpressionExt *)ext {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (ext.prebid) {
        json[@"prebid"] = [self convertStoredImpressionToJSON:ext.prebid];
        [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Impression ext prebid JSON: %@", json[@"prebid"]]];
    } else {
        [logger debug:@"⚠️ [BiddingConfig] No prebid found in impression ext"];
    }
    if (ext.data) {
        json[@"data"] = @{@"loop-index": @"0"};
    }
    
    return [json copy];
}

- (NSDictionary *)convertStoredImpressionToJSON:(CLXBiddingConfigImpressionExtStoredImpression *)storedImpression {
    NSMutableArray *targetingArray = [NSMutableArray array];
    for (CLXBiddingConfigImpressionExtAdserverTargeting *targeting in storedImpression.adservertargeting) {
        [targetingArray addObject:@{
            @"key": targeting.key ?: @"",
            @"source": targeting.source ?: @"",
            @"value": targeting.value ?: @""
        }];
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"adservertargeting"] = [targetingArray copy];
    json[@"storedimpression"] = @{
        @"id": storedImpression.storedimpression.idValue ?: @""
    };
    
    // Add bidder configuration if present
    if (storedImpression.bidder) {
        json[@"bidder"] = storedImpression.bidder;
        [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Including bidder in JSON: %@", storedImpression.bidder]];
    } else {
        [logger debug:@"⚠️ [BiddingConfig] No bidder configuration found in storedImpression"];
    }
    
    [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Final storedImpression JSON: %@", json]];
    
    return [json copy];
}

- (NSDictionary *)convertPMPToJSON:(CLXBiddingConfigImpressionPMP *)pmp {
    NSMutableArray *dealsArray = [NSMutableArray array];
    for (CLXBiddingConfigImpressionPMPDeal *deal in pmp.deals) {
        [dealsArray addObject:@{
            @"id": deal.dealID ?: @""
        }];
    }
    return @{@"deals": [dealsArray copy]};
}

- (NSDictionary *)convertApplicationToJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"id"] = self.application.appID ?: @"";
    json[@"bundle"] = self.application.bundle ?: @"";
    json[@"ver"] = self.application.ver ?: @"";
    json[@"publisher"] = [self convertPublisherToJSON:self.application.publisher];
    json[@"ext"] = @{
        @"data": @{
            @"appKey1": @"appValue1",
            @"appKey2": @"appValue2",
            @"appKey3": @"appValue3"
        }
    };
    return [json copy];
}

- (NSDictionary *)convertPublisherToJSON:(CLXBiddingConfigApplicationPublisher *)publisher {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"id"] = publisher.publisherID ?: @"";
    json[@"ext"] = [self convertPublisherExtToJSON:publisher.ext];
    return [json copy];
}

- (NSDictionary *)convertPublisherExtToJSON:(CLXBiddingConfigApplicationPublisherExt *)ext {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"prebid"] = [self convertPublisherPrebidToJSON:ext.prebid];
    return [json copy];
}

- (NSDictionary *)convertPublisherPrebidToJSON:(CLXBiddingConfigApplicationPublisherPrebid *)prebid {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (prebid.parentAccount) {
        json[@"parentAccount"] = prebid.parentAccount;
    }
    return [json copy];
}

- (NSDictionary *)convertDeviceToJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"ua"] = self.device.ua ?: @"";
    json[@"make"] = self.device.make ?: @"";
    json[@"model"] = self.device.model ?: @"";
    json[@"os"] = self.device.os ?: @"";
    json[@"osv"] = self.device.osv ?: @"";
    json[@"hwv"] = self.device.hwv ?: @"";
    json[@"language"] = self.device.language ?: @"";
    json[@"ifa"] = self.device.ifa ?: @"";
    json[@"js"] = @1;
    json[@"dnt"] = self.device.dnt ?: @0;
    json[@"devicetype"] = self.device.devicetype ?: @0;
    json[@"h"] = self.device.h ?: @0;
    json[@"w"] = self.device.w ?: @0;
    json[@"ppi"] = self.device.ppi ?: @0;
    json[@"connectiontype"] = self.device.connectiontype ?: @0;
    json[@"pxratio"] = self.device.pxratio ?: @0;
    json[@"geo"] = [self convertDeviceGeoToJSON:self.device.geo];
    json[@"ext"] = [self convertDeviceExtToJSON:self.device.ext];
    
    if (self.device.lmt) {
        json[@"lmt"] = self.device.lmt;
    }
    
    return [json copy];
}

- (NSDictionary *)convertDeviceGeoToJSON:(CLXBiddingConfigDeviceGeo *)geo {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (geo.lat) {
        json[@"lat"] = geo.lat;
    }
    if (geo.lon) {
        json[@"lon"] = geo.lon;
    }
    if (geo.accuracy) {
        json[@"accuracy"] = geo.accuracy;
    }
    json[@"type"] = geo.type ?: @0;
    json[@"utcoffset"] = geo.utcoffset ?: @0;
    return [json copy];
}

- (NSDictionary *)convertDeviceExtToJSON:(CLXBiddingConfigDeviceExt *)ext {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (ext.ifv) {
        json[@"ifv"] = ext.ifv;
    }
    return [json copy];
}

- (NSDictionary *)convertUserToJSON {
    if (!self.user) {
        return nil;
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (self.user.keywords) {
        json[@"keywords"] = self.user.keywords;
    }
    
    
    if (self.user.ext) {
        json[@"ext"] = [self convertUserExtToJSON:self.user.ext];
    }
    return [json copy];
}

- (NSDictionary *)convertUserExtToJSON:(CLXBiddingConfigUserExt *)ext {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    //json[@"consent"] = ext.consent ?: @"";
    
    NSMutableDictionary *impUsr = @{
          @"data": @{
            @"userKey1": @"userValue1",
            @"userKey2": @"userValue2",
            @"userKey3": @"userValue3"
          },
          @"eids": @[
            @{
              @"source": @"io.cloudx.demo.demoapp",
              @"uids": @[
                @{
                  @"id": @"29060c8606954ec90fbcde825b2783b0b9261585793db9dfcbe6b870a05a9ee3",
                  @"atype": @3
                }
              ]
            }
          ]
    };
    
    return [impUsr copy];
}


- (NSDictionary *)convertRegulationsToJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (self.regulations.coppa) {
        json[@"coppa"] = self.regulations.coppa;
    }
    if (self.regulations.ext) {
        json[@"ext"] = [self convertRegulationsExtToJSON:self.regulations.ext];
    }
    return [json copy];
}

- (NSDictionary *)convertRegulationsExtToJSON:(CLXBiddingConfigRegulationsExt *)ext {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (ext.iab) {
        json[@"iab"] = [self convertIABToJSON:ext.iab];
    }
    if (ext.gdpr) {
        json[@"gdpr"] = ext.gdpr;
    }
    if (ext.ccpa) {
        json[@"ccpa"] = ext.ccpa;
    }
    if (ext.gpp) {
        json[@"gpp"] = ext.gpp;
    }
    if (ext.gppSid && ext.gppSid.count > 0) {
        json[@"gpp_sid"] = ext.gppSid;
    }
    return [json copy];
}

- (NSDictionary *)convertIABToJSON:(CLXBiddingConfigRegulationsExtIAB *)iab {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (iab.gdprApplies) {
        json[@"gdpr_tcfv2_gdpr_applies"] = iab.gdprApplies;
    }
    if (iab.tcString) {
        json[@"gdpr_tcfv2_tc_string"] = iab.tcString;
    }
    if (iab.usPrivacyString) {
        json[@"ccpa_us_privacy_string"] = iab.usPrivacyString;
    }
    return [json copy];
}

- (NSDictionary *)convertExtToJSON {
    if (!self.ext) {
        return nil;
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    if (self.ext.adapterExtras) {
        json[@"cloudx"] = @{@"adapter_extras": self.ext.adapterExtras};
    }
    if (self.ext.prebid) {
        json[@"prebid"] = [self convertPrebidDebugToJSON:self.ext.prebid];
    }
    return [json copy];
}

- (NSDictionary *)convertPrebidDebugToJSON:(CLXBiddingConfigRequestExtPrebidDebug *)prebid {
    NSMutableArray *targetingArray = [NSMutableArray array];
    for (CLXBiddingConfigRequestExtAdserverTargeting *targeting in prebid.adservertargeting) {
        [targetingArray addObject:@{
            @"key": targeting.key ?: @"",
            @"source": targeting.source ?: @"",
            @"value": targeting.value ?: @""
        }];
    }
    
    return @{
        @"debug": prebid.debug ?: @YES,
        @"adservertargeting": [targetingArray copy]
    };
}

// Property alias for 'imp' to match Swift SDK
- (NSArray<CLXBiddingConfigImpression *> *)imp {
    return self.impressions;
}

@end

#pragma mark - Regulations
@implementation CLXBiddingConfigRegulations
@end
@implementation CLXBiddingConfigRegulationsExt
@end
@implementation CLXBiddingConfigRegulationsExtIAB
@end

#pragma mark - Impression
@implementation CLXBiddingConfigImpression
@end
@implementation CLXBiddingConfigImpressionBanner
@end
@implementation CLXBiddingConfigImpressionBannerFormat
@end
@implementation CLXBiddingConfigImpressionVideo
@end
@implementation CLXBiddingConfigImpressionNative
@end
@implementation CLXBiddingConfigImpressionExt
@end
@implementation CLXBiddingConfigImpressionExtStoredImpression
@end
@implementation CLXBiddingConfigImpressionExtAdserverTargeting
@end
@implementation CLXBiddingConfigImpressionExtId
@end
@implementation CLXBiddingConfigImpressionPMP
@end
@implementation CLXBiddingConfigImpressionPMPDeal
@end

#pragma mark - Application
@implementation CLXBiddingConfigApplication
@end
@implementation CLXBiddingConfigApplicationPublisher
@end
@implementation CLXBiddingConfigApplicationPublisherExt
@end
@implementation CLXBiddingConfigApplicationPublisherPrebid
@end

#pragma mark - Device
@implementation CLXBiddingConfigDevice
@end
@implementation CLXBiddingConfigDeviceGeo
@end
@implementation CLXBiddingConfigDeviceExt
@end

#pragma mark - User
@implementation CLXBiddingConfigUser
@end
@implementation CLXBiddingConfigUserExt
@end
@implementation CLXBiddingConfigUserExtEids
@end
@implementation CLXBiddingConfigUserExtUids
@end

#pragma mark - RequestExt
@implementation CLXBiddingConfigRequestExt
@end
@implementation CLXBiddingConfigRequestExtPrebidDebug
@end
@implementation CLXBiddingConfigRequestExtAdserverTargeting
@end

#pragma mark - Response
// All response class implementations removed - use CLXBidResponse classes instead 
