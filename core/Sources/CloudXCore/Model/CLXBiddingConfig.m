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
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/NSDictionary+DynamicPath.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXSessionMetrics.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>

// Internal methods category for accessing privacy methods that are not in public header
// TEMP: Remove CLXPrivacyService private interface once server supports GDPR/COPPA
@interface CLXPrivacyService (Internal)
- (nullable NSString *)gdprConsentString;
- (nullable NSNumber *)gdprApplies;
- (nullable NSNumber *)coppaApplies;
@end

// Privacy service parameter is now required in main interface - no separate testing category needed

#pragma mark - CLXBiddingConfig
@implementation CLXBiddingConfig
@end

static CLXLogger *logger;

__attribute__((constructor))
static void initializeLogger() {
    logger = [[CLXLogger alloc] initWithCategory:@"BiddingConfig.m"];
}

#pragma mark - CLXBiddingConfigRequest

@interface CLXBiddingConfigRequest ()
@property (nonatomic, strong, nullable) CLXPrivacyService *privacyService;
@end

@implementation CLXBiddingConfigRequest

@synthesize test = _test;

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
                privacyService:(CLXPrivacyService *)privacyService
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
        
        // Calculate screen dimensions in pixels (not points)
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat scale = [[UIScreen mainScreen] scale];
        NSInteger screenWidth = (NSInteger)(screenRect.size.width * scale);
        NSInteger screenHeight = (NSInteger)(screenRect.size.height * scale);
        
        // OpenRTB device.w/h should always be full screen pixels, not ad size
        // Ad format dimensions are handled separately in banner.format array

        // Create banner format with actual ad dimensions
        CLXBiddingConfigImpressionBannerFormat *format = [[CLXBiddingConfigImpressionBannerFormat alloc] init];
        if (adType == CLXAdTypeMrec) {
            format.w = @300;
            format.h = @250;
        } else if (adType == CLXAdTypeBanner) {
            format.w = @320;
            format.h = @50;
        } else {
            // For interstitial, rewarded, native: use full screen dimensions
            format.w = @(screenWidth);
            format.h = @(screenHeight);
        }

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
        
        // Loop-index logic: matches Android behavior
        // - Interstitials and Rewarded ads always use fixed value (1)
        // - Banner/MREC ads use per-placement counter (NOT incremented here, only retrieved)
        NSString *loopIndexValue;
        if (adType == CLXAdTypeInterstitial || adType == CLXAdTypeRewarded) {
            // Interstitials and Rewarded: always use 1 (fixed value, never increment)
            loopIndexValue = @"1";
            [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Using fixed loop-index=1 for %@ ad", 
                          adType == CLXAdTypeInterstitial ? @"interstitial" : @"rewarded"]];
        } else {
            // Banner/MREC/Native: use per-placement counter from tracker
            // Note: Counter is incremented separately by the ad load logic, not here
            NSDictionary<NSString *, NSString *> *bannerUserDict = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreBannerUserKeyValueKey];
            loopIndexValue = bannerUserDict[@"loop-index"] ?: @"1";
            [logger debug:[NSString stringWithFormat:@"🔧 [BiddingConfig] Using placement loop-index=%@ for banner/MREC", loopIndexValue]];
        }
        
        // Create impression ext
        CLXBiddingConfigImpressionExt *impExt = [[CLXBiddingConfigImpressionExt alloc] init];
        impExt.prebid = storedImpression;
        
        // Set loop-index in impression data
        impExt.data = @{@"loop-index": loopIndexValue};
        
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
        
        // NEW: Add session metrics to impression (iOS feature parity with Android)
        CLXSessionMetrics *sessionMetrics = [[CLXSessionMetricsTracker sharedInstance] getMetrics];
        impression.metric = [self sessionMetricsToJSON:sessionMetrics];
        
        [logger debug:[NSString stringWithFormat:@"📊 [BiddingConfig] Added %lu session metrics to impression",
                      (unsigned long)impression.metric.count]];
        
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
        
        // Read app key values from UserDefaults (empty if not set)
        // Note: iOS doesn't currently have a separate app key values API like Android
        // This is reserved for future use
        NSDictionary *appKeyValues = @{};
        
        CLXBiddingConfigApplication *application = [[CLXBiddingConfigApplication alloc] init];
        // Use appID from SDK init response for bid request app.id field
        // Fallback to empty string if impModel or sdkConfig is nil
        application.appID = impModel.sdkConfig.appID ?: @"";
        application.bundle = bundle;
        application.ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        application.publisher = publisher;
        application.ext.data = appKeyValues;
        
        self.application = application;
        
        // Create device
        CLXGeoLocationService *geoService = [CLXGeoLocationService shared];
        CLXBiddingConfigDeviceGeo *geo = [[CLXBiddingConfigDeviceGeo alloc] init];
        
        // Extract lat/lon from CloudFront headers (raw geo headers)
        NSDictionary *rawGeoHeaders = [geoService geoHeaders];
        if (rawGeoHeaders) {
            NSString *latString = rawGeoHeaders[@"cloudfront-viewer-latitude"];
            NSString *lonString = rawGeoHeaders[@"cloudfront-viewer-longitude"];
            if (latString && [latString isKindOfClass:[NSString class]]) {
                geo.lat = @([latString doubleValue]);
            }
            if (lonString && [lonString isKindOfClass:[NSString class]]) {
                geo.lon = @([lonString doubleValue]);
            }
        }
        
        // Note: accuracy not available from CloudFront headers
        geo.accuracy = location ? @(location.horizontalAccuracy) : nil;
        geo.type = @1;
        geo.utcoffset = @([[NSTimeZone localTimeZone] secondsFromGMT] / 60);
        geo.country = [geoService countryCode];
        geo.region = [geoService region];
        geo.city = [geoService city];
        geo.zip = [geoService zip];
        geo.metro = [geoService metro];
        
        CLXBiddingConfigDeviceExt *deviceExt = [[CLXBiddingConfigDeviceExt alloc] init];
        deviceExt.ifv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        
        // This handles all configuration scenarios with proper debug/production safety
        NSString *ifa = [settings getIFA];
        
        CLXBiddingConfigDevice *device = [[CLXBiddingConfigDevice alloc] init];
        device.ua = userAgent ?: @"ua";
        device.make = @"Apple";
        device.model = [[UIDevice currentDevice] model];
        device.os = @"iOS";
        device.osv = [[UIDevice currentDevice] systemVersion];
        device.hwv = [[UIDevice currentDevice] systemVersion];
        device.language = [[NSLocale currentLocale] languageCode];
        device.ifa = ifa;
        device.dnt = @0;
        device.devicetype = @([CLXSystemInformation shared].deviceType); // Use robust device type detection
        device.h = @(screenHeight);
        device.w = @(screenWidth);
        device.ppi = @([[UIScreen mainScreen] scale] * 163); // Approximate PPI
        device.connectiontype = @([CLXReachabilityService shared].currentReachabilityType); // Use robust connection type detection
        device.lmt = nil;
        device.pxratio = @([[UIScreen mainScreen] scale]);
        device.geo = geo;
        device.ext = deviceExt;
        
        _device = device;
        
        // Create user
        NSString *hashedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreHashedUserIDKey];
        NSString *aiPrompt = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreAIPromptKey];
        NSString *userKeywords = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreUserKeywordsKey];
        
        // Only create eids if publisher explicitly provided hashed user ID
        NSArray<CLXBiddingConfigUserExtEids *> *eids = nil;
        if (hashedUserId && hashedUserId.length > 0) {
            CLXBiddingConfigUserExtUids * uids = [[CLXBiddingConfigUserExtUids alloc] init];
            uids.id = hashedUserId;
            uids.atype = @"3";
            
            CLXBiddingConfigUserExtEids *eidItem = [[CLXBiddingConfigUserExtEids alloc] init];
            eidItem.source = bundle;
            eidItem.uids = @[uids];
            
            eids = @[eidItem];
        }
        
        // Read user key values from UserDefaults (empty if not set)
        // Publishers can set these via setKeyValueDictionary API
        NSDictionary *userKeyValues = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCLXCoreUserKeyValueKey] ?: @{};
        
        CLXBiddingConfigUserExt *userExt = [[CLXBiddingConfigUserExt alloc] init];
        //userExt.consent = @"gdpr-consent-string";
        userExt.data = userKeyValues;
        userExt.eids = eids;
        
        CLXBiddingConfigUser *user = [[CLXBiddingConfigUser alloc] init];
        user.keywords = userKeywords.length > 0 ? userKeywords : nil;
        user.ext = userExt;
        
        _user = user;
        
        // Store the privacy service for use in JSON conversion
        _privacyService = privacyService;
        
        // Create regulations - only CCPA is supported by server currently
        // ⚠️ GDPR and COPPA are temporarily disabled as server support is not yet implemented
        // Including GDPR/COPPA data causes 502 bid request errors
        CLXBiddingConfigRegulationsExtIAB *iab = [[CLXBiddingConfigRegulationsExtIAB alloc] init];
        iab.usPrivacyString = [privacyService ccpaPrivacyString]; // CCPA is server-supported

        CLXBiddingConfigRegulationsExt *regExt = [[CLXBiddingConfigRegulationsExt alloc] init];
        regExt.iab = iab;
        
        // Include GPP compliance data in bid request regulations
        [self populateGPPDataForRegulationsExt:regExt withPrivacyService:privacyService];

        CLXBiddingConfigRegulations *regulations = [[CLXBiddingConfigRegulations alloc] init];
        regulations.ext = regExt;

        // TODO: Re-enable GDPR and COPPA once server support is implemented
        // iab.gdprApplies = [privacyService gdprApplies];
        // iab.tcString = [privacyService gdprConsentString];
        // regExt.gdpr = [privacyService gdprApplies];
        // regulations.coppa = [privacyService coppaApplies];

        _regulations = regulations;
        
        // Apply privacy-aware data clearing when required
        // Note: IFA is already privacy-aware at source level (CLXSettings.getIFA)
        BOOL shouldClearPersonalData = [privacyService shouldClearPersonalData];
        if (shouldClearPersonalData) {
            // Clear precise location data but keep general geo fields for contextual targeting
            if (_device.geo) {
                _device.geo.lat = nil;
                _device.geo.lon = nil;
                _device.geo.accuracy = nil;
                // Keep country, region, city, zip, and metro for contextual targeting
                // This matches Android implementation which always includes geo data
                // regardless of privacy settings (only lat/lon/accuracy are cleared)
                // Keep utcoffset for timezone-based functionality
            }
        }
        
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
        
        // Store loop index for win/loss tracking
        NSInteger loopIndexInt = [loopIndexValue integerValue];
        [[CLXTrackingFieldResolver shared] setLoopIndex:_requestID loopIndex:loopIndexInt];
        [logger debug:[NSString stringWithFormat:@"📊 [BiddingConfig] Stored loop-index=%ld for auction: %@", (long)loopIndexInt, _requestID]];
        
        // Check if test mode has been forced via internal API (for demo/test apps only)
        NSNumber *forceTestMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"CLXCore_Internal_ForceTestMode"];
        
        if (forceTestMode && [forceTestMode boolValue]) {
            _test = @1;
            [logger debug:@"🔧 [BiddingConfig] Force test mode enabled - test flag set to: 1"];
        } else {
            // Set test flag based on simulator detection and build configuration
            // Simulator (any build) → test=1 (Meta registers simulator as test device)
            // Real device + DEBUG → test=1 (device registered as test device in Meta adapter)
            // Real device + RELEASE → test=0 (production mode)
            #if TARGET_IPHONE_SIMULATOR
            _test = @1;
            [logger debug:@"🔧 [BiddingConfig] Simulator detected - test flag set to: 1"];
            #else
            #ifdef DEBUG
            _test = @1;
            [logger debug:@"🔧 [BiddingConfig] Real device + DEBUG build - test flag set to: 1"];
            #else
            _test = @0;
            [logger debug:@"🔧 [BiddingConfig] Real device + RELEASE build - test flag set to: 0"];
            #endif
            #endif
        }
    }
    return self;
}

// Privacy service parameter is now required in main initializer - no separate method needed

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
    
    // Add test flag (OpenRTB 2.5 spec: 0 = production, 1 = test)
    // Only include if explicitly set (non-nil) - nil means exclude from request entirely
    if (self.test != nil) {
        json[@"test"] = self.test;
        [logger debug:[NSString stringWithFormat:@"🧪 [BiddingConfig] Test flag included in request: %@", self.test]];
    } else {
        [logger debug:@"🧪 [BiddingConfig] Test flag excluded from request (nil)"];
    }
    
    // Inject key-value pairs at server-configured paths
    [self injectKeyValuesIntoRequest:json];
    
    // Debug logging
    [logger debug:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] Final bid request - Keys: %@, Imp count: %lu", [json allKeys], (unsigned long)[json[@"imp"] count]]];
    
    // Log the complete JSON structure
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        [logger error:[NSString stringWithFormat:@"❌ [ObjC-BiddingConfig] JSON serialization error: %@", error]];
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        [logger info:[NSString stringWithFormat:@"[ObjC-BiddingConfig] %@", jsonString]];
    }
    
    return [json copy];
}

- (void)injectKeyValuesIntoRequest:(NSMutableDictionary *)json {
    CLXKeyValueState *state = [CLXKeyValueState shared];
    CLXSDKConfigKeyValueObject *paths = state.keyValuePaths;
    
    if (!paths) {
        [logger debug:@"⚠️ [ObjC-BiddingConfig] No key-value paths configuration available"];
        return;
    }
    
    BOOL shouldRemovePII = [self.privacyService shouldClearPersonalData];
    
    // Inject user key-values (respect privacy)
    if (paths.userKeyValues && !shouldRemovePII && state.userKeyValues.count > 0) {
        NSDictionary *userKV = [state.userKeyValues copy];
        [logger debug:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] Injecting %lu user key-values at path: %@", (unsigned long)userKV.count, paths.userKeyValues]];
        [json putAtDynamicPath:paths.userKeyValues value:userKV];
    }
    
    // Inject app key-values (not affected by privacy)
    if (paths.appKeyValues && state.appKeyValues.count > 0) {
        NSDictionary *appKV = [state.appKeyValues copy];
        [logger debug:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] Injecting %lu app key-values at path: %@", (unsigned long)appKV.count, paths.appKeyValues]];
        [json putAtDynamicPath:paths.appKeyValues value:appKV];
    }
    
    // Inject hashed user ID as eids (respect privacy)
    if (paths.eids && !shouldRemovePII && state.hashedUserId) {
        NSString *bundle = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
        NSDictionary *eid = @{
            @"source": bundle,
            @"uids": @[@{
                @"id": state.hashedUserId,
                @"atype": @3
            }]
        };
        [logger debug:[NSString stringWithFormat:@"🔧 [ObjC-BiddingConfig] Injecting hashed user ID at path: %@", paths.eids]];
        [json putAtDynamicPath:paths.eids value:eid];
    }
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
    if (impression.metric) {
        json[@"metric"] = impression.metric;
    }
    
    return [json copy];
}

#pragma mark - Session Metrics

/**
 * Converts session metrics to OpenRTB metric array format.
 * Each metric object contains: type, value, vendor.
 *
 * Matches Android implementation in BidRequestProvider.kt:271-290
 */
- (NSArray *)sessionMetricsToJSON:(CLXSessionMetrics *)metrics {
    if (!metrics) {
        return @[];
    }
    
    NSMutableArray *metricsArray = [NSMutableArray arrayWithCapacity:7];
    
    // Helper to add metric object (matching Android format exactly)
    void (^addMetric)(NSString *, float) = ^(NSString *type, float value) {
        [metricsArray addObject:@{
            @"type": type,
            @"value": @(value),
            @"vendor": @"EXCHANGE"
        }];
    };
    
    // Add all session metrics (same order as Android)
    addMetric(@"session_depth", metrics.depth);
    addMetric(@"session_depth_banner", metrics.bannerDepth);
    addMetric(@"session_depth_medium_rectangle", metrics.mediumRectangleDepth);
    addMetric(@"session_depth_full", metrics.fullDepth);
    addMetric(@"session_depth_native", metrics.nativeDepth);
    addMetric(@"session_depth_rewarded", metrics.rewardedDepth);
    addMetric(@"session_duration", metrics.durationSeconds);
    
    [logger debug:[NSString stringWithFormat:
        @"📊 Session metrics: depth=%.0f, banner=%.0f, mrec=%.0f, full=%.0f, native=%.0f, rewarded=%.0f, duration=%.1fs",
        metrics.depth, metrics.bannerDepth, metrics.mediumRectangleDepth, 
        metrics.fullDepth, metrics.nativeDepth, metrics.rewardedDepth, metrics.durationSeconds]];
    
    return [metricsArray copy];
}

#pragma mark - Impression JSON Conversion

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
        json[@"data"] = ext.data;
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
    
    // Use actual app extension data instead of hardcoded values
    // Only include if data dictionary is non-empty
    if (self.application.ext && self.application.ext.data && [self.application.ext.data count] > 0) {
        json[@"ext"] = @{
            @"data": self.application.ext.data
        };
    }
    
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
    if (geo.country) {
        json[@"country"] = geo.country;
    }
    json[@"type"] = geo.type ?: @0;
    json[@"utcoffset"] = geo.utcoffset ?: @0;
    
    // Enhanced geo fields
    if (geo.country) {
        json[@"country"] = geo.country;
    }
    if (geo.region) {
        json[@"region"] = geo.region;
    }
    if (geo.city) {
        json[@"city"] = geo.city;
    }
    if (geo.zip) {
        json[@"zip"] = geo.zip;
    }
    if (geo.metro) {
        json[@"metro"] = geo.metro;
    }
    
    return [json copy];
}

#pragma mark - Privacy Helper Methods

/**
 * Populates GPP compliance data for regulations extension
 * @param regExt The regulations extension to populate
 * @param privacyService The privacy service containing GPP data
 */
- (void)populateGPPDataForRegulationsExt:(CLXBiddingConfigRegulationsExt *)regExt 
                      withPrivacyService:(CLXPrivacyService *)privacyService {
    NSString *gppString = [privacyService gppString];
    if (gppString) {
        regExt.gpp = gppString;
    }
    
    NSArray<NSNumber *> *gppSid = [privacyService gppSid];
    if (gppSid && gppSid.count > 0) {
        regExt.gppSid = gppSid;
    }
}

#pragma mark - JSON Conversion Methods

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
    // Check if privacy service requires data clearing
    if (_privacyService && [_privacyService shouldClearPersonalData]) {
        // Return empty dictionary when privacy requires data clearing
        return @{};
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // Use actual user data instead of hardcoded values
    // Only include if data dictionary is non-empty
    if (ext.data && [ext.data count] > 0) {
        json[@"data"] = ext.data;
    }
    
    // Use actual eids with proper iOS bundle identifier
    if (ext.eids && ext.eids.count > 0) {
        NSMutableArray *eidsArray = [NSMutableArray array];
        
        for (CLXBiddingConfigUserExtEids *eidItem in ext.eids) {
            NSMutableArray *uidsArray = [NSMutableArray array];
            if (eidItem.uids && eidItem.uids.count > 0) {
                for (CLXBiddingConfigUserExtUids *uid in eidItem.uids) {
                    [uidsArray addObject:@{
                        @"id": uid.id ?: @"",
                        @"atype": uid.atype ?: @"3"
                    }];
                }
            }
            
            [eidsArray addObject:@{
                @"source": eidItem.source ?: @"",
                @"uids": [uidsArray copy]
            }];
        }
        
        json[@"eids"] = [eidsArray copy];
    }
    
    return [json copy];
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
    // Include GPP compliance data in bid request regulations
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
        NSMutableDictionary *cloudxExt = [NSMutableDictionary dictionary];
        cloudxExt[@"adapter_extras"] = self.ext.adapterExtras;
        cloudxExt[@"sdkReleaseVersion"] = [CLXSystemInformation shared].sdkVersion;
        json[@"cloudx"] = [cloudxExt copy];
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
