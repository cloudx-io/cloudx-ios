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
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <CloudXCore/CLXORTBConstants.h>
#import <CloudXCore/CLXSKAdNetworkService.h>


#pragma mark - Video Bid Request Constants
/**
 * OpenRTB 2.5 Video Object Configuration Constants
 *
 * These values are sent in bid requests to tell DSPs/bidders what video content
 * constraints we have. They constrain the VIDEO FILE that bidders return, NOT
 * the total on-screen ad experience time.
 *
 * IMPORTANT DISTINCTION:
 *   - These values → Constrain video FILE length in bid response
 *   - Force close timeout → Constrains total ON-SCREEN time (video + end card + interaction)
 *   - See CLXPublisherFullscreenAdBase.m for force close timeout constants
 *
 * Industry standard: maxduration=60 is typical for rewarded/interstitial video ads.
 */

/// Minimum video duration in seconds
/// Rationale: Prevents extremely short videos that don't deliver advertiser value.
/// Most DSPs won't bid with <5s videos anyway.
static const NSInteger kCLXVideoMinDuration = 5;

/// Maximum video duration in seconds
/// Rationale: 60s is industry standard for rewarded video max. Balances:
///   - Advertiser message delivery
///   - User attention span
///   - Completion rate optimization (drops significantly past 30-45s)
/// Note: Most actual creatives are 15-30s; 60s is the upper bound.
///
/// 🔧 PUBLISHER CONFIGURABILITY CANDIDATE:
///    Publishers may want shorter maxduration (e.g., 30s) for better UX,
///    or this could be set per-placement via server config.
static const NSInteger kCLXVideoMaxDuration = 60;

/// Number of seconds a video must play before skip button appears (when skippable)
/// Rationale: Industry standard is 5 seconds. Ensures advertisers get minimum exposure
/// before users can skip. Used for interstitials (rewarded videos are non-skippable).
///
/// 🔧 PUBLISHER CONFIGURABILITY CANDIDATE:
///    Some publishers prefer shorter (3s) or longer (10s) skip delays.
///    Could be configurable per-placement.
static const NSInteger kCLXVideoSkipAfterSeconds = 5;

/// Minimum video duration before skip is allowed (skipmin field)
/// Set to 0 = no minimum requirement (skipafter handles the timing)
static const NSInteger kCLXVideoSkipMinDuration = 0;

/// Video playback method(s) supported
/// 1 = Auto-play with sound on (standard for fullscreen video ads)
/// Other values: 2=auto-play sound off, 3=click-to-play, 4=mouse-over
static const NSInteger kCLXVideoPlaybackMethodAutoPlaySoundOn = 1;

/// Video start delay (pre-roll, mid-roll, post-roll positioning)
/// 0 = pre-roll (starts immediately when ad displays)
/// >0 = mid-roll delay in seconds
/// -1 = generic mid-roll, -2 = generic post-roll
static const NSInteger kCLXVideoStartDelayPreRoll = 0;

// Internal methods category for accessing privacy methods
@interface CLXPrivacyService (Internal)
- (nullable NSString *)gdprConsentString;
- (nullable NSNumber *)gdprApplies;
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

/**
 * Converts iOS ReachabilityType enum to ORTB 2.5 connection type values.
 * ORTB 2.5 references AdCOM v1.0 for connection types.
 *
 * AdCOM v1.0 connection type values (ORTB standard):
 * 0 = Unknown
 * 1 = Ethernet
 * 2 = WIFI
 * 3 = Cellular Network - Unknown Generation
 * 4 = Cellular Network - 2G
 * 5 = Cellular Network - 3G
 * 6 = Cellular Network - 4G
 * 7 = Cellular Network - 5G
 *
 * Current iOS SDK support (ReachabilityType enum):
 * - WiFi → 2 ✓
 * - 2G/3G/4G → 4/5/6 ✓
 * - 5G → Not yet supported (would map to 7)
 *
 * NOTE: iOS CLXReachabilityService currently defaults all cellular to 4G.
 * Actual 2G/3G/4G/5G detection requires CoreTelephony API implementation.
 * TODO: Add ReachabilityTypeWWAN5G case when detection is implemented.
 */
static NSInteger ReachabilityTypeToORTBConnectionType(ReachabilityType type) {
    switch (type) {
        case ReachabilityTypeWiFi:
            return 2; // WIFI
        case ReachabilityTypeWWAN2G:
            return 4; // Cellular 2G
        case ReachabilityTypeWWAN3G:
            return 5; // Cellular 3G
        case ReachabilityTypeWWAN4G:
            return 6; // Cellular 4G
        // case ReachabilityTypeWWAN5G:  // TODO: Add when enum is extended
        //     return 7; // Cellular 5G
        case ReachabilityTypeNone:
        case ReachabilityTypeUnknown:
        default:
            return 0; // Unknown
    }
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
        banner.formats = @[format];
        // ORTB 2.5: topframe indicates if ad is in top frame (1) or nested iframe (0).
        // Native mobile apps always render ads directly in the view hierarchy - there are no
        // iframes like in web environments. Therefore topframe is always 1 for iOS/Android SDKs.
        banner.topframe = @1;
        
        // ORTB 2.5 Ad Position (Section 5.4)
        // We can ONLY know position definitively for fullscreen ad types.
        // For inline ads (banner, MREC, native), position depends entirely on where
        // the publisher places the view. Best practice is to expose a public API
        // (e.g. banner.adPosition) to let publishers explicitly declare this.
        // Auto-detection via view frames is unreliable and discouraged.
        switch (adType) {
            case CLXAdTypeInterstitial:
                // Interstitials are always fullscreen - this is definitive
                banner.pos = CLXORTBAdPositionToNumber(CLXORTBAdPositionFullScreen);
                break;
            case CLXAdTypeRewarded:
                // Rewarded ads are always fullscreen - this is definitive
                banner.pos = CLXORTBAdPositionToNumber(CLXORTBAdPositionFullScreen);
                break;
            case CLXAdTypeBanner:
            case CLXAdTypeMrec:
            case CLXAdTypeNative:
            default:
                // Inline ads: position unknown without view frame detection
                banner.pos = CLXORTBAdPositionToNumber(CLXORTBAdPositionUnknown);
                break;
        }
        
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
        
        // ORTB 2.5: Video duration and skip configuration
        // See constant definitions at top of file for detailed rationale on each value
        video.minduration = @(kCLXVideoMinDuration);
        video.maxduration = @(kCLXVideoMaxDuration);
        video.startdelay = @(kCLXVideoStartDelayPreRoll);
        video.skip = (adType == CLXAdTypeRewarded) ? @0 : @1;  // Rewarded = non-skippable, Interstitial = skippable
        video.skipmin = @(kCLXVideoSkipMinDuration);
        video.skipafter = @(kCLXVideoSkipAfterSeconds);        // Only applies when skip=1 (interstitials)
        video.playbackmethod = @[@(kCLXVideoPlaybackMethodAutoPlaySoundOn)];
        
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
        
        // Create impression ext
        CLXBiddingConfigImpressionExt *impExt = [[CLXBiddingConfigImpressionExt alloc] init];
        impExt.prebid = storedImpression;
        
        // Create SKAdNetwork object for iOS attribution (IAB SKAN spec)
        // This tells bidders which SKAN versions are supported and which network IDs
        // are in the publisher's Info.plist for attribution
        CLXSKAdNetworkService *skadService = [[CLXSKAdNetworkService alloc] initWithSystemVersion:[[UIDevice currentDevice] systemVersion]];
        NSArray<NSString *> *skadVersions = skadService.versions;
        NSArray<NSString *> *skadNetworkIds = skadService.skadPlistIds;
        
        if (skadVersions.count > 0 || skadNetworkIds.count > 0) {
            CLXBiddingConfigImpressionExtSkadn *skadn = [[CLXBiddingConfigImpressionExtSkadn alloc] init];
            // Highest supported version (last in array)
            skadn.version = skadVersions.lastObject;
            skadn.versions = skadVersions;
            skadn.sourceapp = skadService.sourceApp;
            skadn.skadnetids = skadNetworkIds;
            impExt.skadn = skadn;
            
            [logger debug:[NSString stringWithFormat:@"[BiddingConfig] SKAdNetwork: version=%@, versions=%lu, sourceapp=%@, skadnetids=%lu",
                          skadn.version,
                          (unsigned long)skadn.versions.count,
                          skadn.sourceapp,
                          (unsigned long)(skadn.skadnetids.count ?: 0)]];
        } else {
            [logger debug:@"[BiddingConfig] SKAdNetwork: No SKAN versions or network IDs available"];
        }
        
        // Create native ad if needed
        CLXBiddingConfigImpressionNative *native = nil;
        if (adType == CLXAdTypeNative && nativeAdRequirements) {
            [logger debug:[NSString stringWithFormat:@"Creating native ad with requirements: %@", nativeAdRequirements]];
            
            // Encode nativeAdRequirements to JSON string like Swift version
            NSError *jsonError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:nativeAdRequirements options:0 error:&jsonError];
            if (jsonError) {
                [logger error:[NSString stringWithFormat:@"Failed to encode native ad requirements: %@", jsonError]];
            } else {
                NSString *requestString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [logger info:[NSString stringWithFormat:@"Native ad requirements encoded: %@", requestString]];
                
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
        // ORTB 2.5: displaymanager identifies the SDK responsible for rendering
        impression.displaymanager = displayManager;
        impression.displaymanagerver = displayManagerVer;
        
        [logger debug:[NSString stringWithFormat:@"Creating impression - AdType: %ld, Dimensions: %ldx%ld", (long)adType, (long)screenWidth, (long)screenHeight]];
        
        impression.instl = (adType == CLXAdTypeInterstitial || adType == CLXAdTypeRewarded) ? @1 : @0;
        // ORTB 2.5: rwdd indicates rewarded ad (1 = rewarded) - only set for rewarded ads
        impression.rwdd = (adType == CLXAdTypeRewarded) ? @1 : nil;
        
        // ORTB 2.5: bidfloor is the minimum bid price for this impression in CPM
        // Only include if explicitly provided (non-zero value indicates publisher floor)
        if (bidFloor && [bidFloor floatValue] > 0) {
            impression.bidfloor = bidFloor;
        }
        
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
        
        [logger debug:[NSString stringWithFormat:@"Impression created - instl:%@, banner:%@, video:%@, native:%@", 
                       impression.instl, 
                       impression.banner ? @"YES" : @"NO", 
                       impression.video ? @"YES" : @"NO", 
                       impression.nativeAd ? @"YES" : @"NO"]];
        
        // NEW: Add session metrics to impression (iOS feature parity with Android)
        CLXSessionMetrics *sessionMetrics = [[CLXSessionMetricsTracker sharedInstance] getMetrics];
        impression.metric = [self sessionMetricsToJSON:sessionMetrics];
        
        [logger debug:[NSString stringWithFormat:@"Added %lu session metrics to impression",
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
        
        // Get DNT (Do Not Track) status from ATT/LAT settings
        BOOL dnt = [CLXAdTrackingService dnt];
        
        // ORTB 2.5: device.ip is intentionally NOT set client-side.
        // The ad exchange server populates device.ip from the HTTP request's source IP.
        // This is the industry-standard approach because:
        // 1. Security: Prevents IP spoofing for geo-arbitrage and fraud
        // 2. Accuracy: Server sees the true client IP from the connection
        // 3. Privacy: Client apps cannot reliably determine their public IP without external calls
        CLXBiddingConfigDevice *device = [[CLXBiddingConfigDevice alloc] init];
        // ORTB 2.5: device.ua is the browser/app user agent string (RECOMMENDED but not REQUIRED).
        // Only include if we have a real user agent - don't send fake/fallback values.
        if (userAgent) {
            device.ua = userAgent;
        }
        device.make = @"Apple";
        // ORTB 2.5: device.model should be the device identifier (e.g., "iPhone15,2")
        device.model = [CLXSystemInformation shared].model;
        device.os = @"iOS";
        device.osv = [[UIDevice currentDevice] systemVersion];
        // ORTB 2.5: device.hwv is the hardware version.
        // Use the device identifier (e.g., "iPhone17,1") which is always available and
        // provides precise hardware info for bidders. This is more valuable than marketing
        // names like "16 Pro" since bidders can map identifiers to exact specs.
        device.hwv = [UIDevice clx_deviceIdentifier];
        device.language = [[NSLocale currentLocale] languageCode];
        device.ifa = ifa;
        device.dnt = @(dnt ? 1 : 0);
        device.devicetype = @([CLXSystemInformation shared].deviceType);
        device.h = @(screenHeight);
        device.w = @(screenWidth);
        device.ppi = @([[UIScreen mainScreen] scale] * 163);
        // ORTB 2.5: connectiontype uses AdCOM v1.0 values (0-7)
        // Convert iOS ReachabilityType to ORTB standard
        device.connectiontype = @(ReachabilityTypeToORTBConnectionType([CLXReachabilityService shared].currentReachabilityType));
        // ORTB 2.5: device.lmt indicates "Limit Ad Tracking" (1 = tracking restricted, 0 = unrestricted)
        device.lmt = @(dnt ? 1 : 0);
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
            uids.atype = @3;
            
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
        
        // Create regulations with privacy compliance data
        CLXBiddingConfigRegulationsExtIAB *iab = [[CLXBiddingConfigRegulationsExtIAB alloc] init];
        
        // CCPA/US Privacy
        iab.usPrivacyString = [privacyService ccpaPrivacyString];
        
        // GDPR/TCF - include consent data when GDPR applies
        NSNumber *gdprApplies = [privacyService gdprApplies];
        if (gdprApplies) {
            iab.gdprApplies = gdprApplies;
            iab.tcString = [privacyService gdprConsentString];
            [logger debug:[NSString stringWithFormat:@"GDPR data included - applies: %@, tcString: %@",
                          gdprApplies, iab.tcString ? @"(present)" : @"(none)"]];
        }

        CLXBiddingConfigRegulationsExt *regExt = [[CLXBiddingConfigRegulationsExt alloc] init];
        regExt.iab = iab;
        
        // Set top-level GDPR flag when applicable
        if (gdprApplies && [gdprApplies boolValue]) {
            regExt.gdpr = gdprApplies;
        }
        
        // Include GPP compliance data in bid request regulations
        [self populateGPPDataForRegulationsExt:regExt withPrivacyService:privacyService];

        CLXBiddingConfigRegulations *regulations = [[CLXBiddingConfigRegulations alloc] init];
        regulations.ext = regExt;

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
        // Debug flag controls verbose logging in server bid responses
        // NO = production (concise responses), YES = verbose debug information
        // Set to NO to match Android SDK behavior and keep responses lightweight
        prebid.debug = @NO;
        prebid.adservertargeting = [prebidArray copy];
        
        CLXBiddingConfigRequestExt *ext = [[CLXBiddingConfigRequestExt alloc] init];
        ext.adapterExtras = [adapterExtras copy];
        ext.prebid = prebid;
        
        _ext = ext;
        _requestID = [[NSUUID UUID] UUIDString];
        
        // ORTB 2.5: Create source object for supply chain transparency
        CLXBiddingConfigSource *source = [[CLXBiddingConfigSource alloc] init];
        // tid = Transaction ID, using the same request ID for consistency
        source.tid = _requestID;
        // fd = 1 indicates exchange/SDK is responsible for final impression decision
        source.fd = @1;
        _source = source;
        
        // Read test mode from SDK init configuration
        // Test mode is set during initializeSDKWithAppKey:testMode:completion:
        // Simulator always has test mode enabled automatically
        BOOL testModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kCLXCoreTestModeKey];
        
        if (testModeEnabled) {
            _test = @1;
            [logger debug:@"Test mode enabled via SDK init - test flag set to: 1"];
        } else {
            _test = @0;
            [logger debug:@"Production mode - test flag set to: 0"];
        }
    }
    return self;
}

// Privacy service parameter is now required in main initializer - no separate method needed

- (NSDictionary *)json {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // Add basic fields
    json[@"id"] = self.requestID ?: @"";
    // ORTB 2.5: Auction type (1 = First Price, 2 = Second Price)
    json[@"at"] = @1;
    json[@"imp"] = [self convertImpressionsToJSON];
    json[@"app"] = [self convertApplicationToJSON];
    json[@"device"] = [self convertDeviceToJSON];
    json[@"user"] = [self convertUserToJSON];
    json[@"regs"] = [self convertRegulationsToJSON];
    json[@"ext"] = [self convertExtToJSON];
    
    // ORTB 2.5: Add source object for supply chain transparency
    if (self.source) {
        json[@"source"] = [self convertSourceToJSON];
    }
    
    if (self.tmax) {
        json[@"tmax"] = self.tmax;
    }
    
    // Add test flag (OpenRTB 2.5 spec: 0 = production, 1 = test)
    // Only include if explicitly set (non-nil) - nil means exclude from request entirely
    if (self.test != nil) {
        json[@"test"] = self.test;
        [logger debug:[NSString stringWithFormat:@"[BiddingConfig] Test flag included in request: %@", self.test]];
    } else {
        [logger debug:@"[BiddingConfig] Test flag excluded from request (nil)"];
    }
    
    // Inject key-value pairs at server-configured paths
    [self injectKeyValuesIntoRequest:json];
    
    // Debug logging
    [logger debug:[NSString stringWithFormat:@"Final bid request - Keys: %@, Imp count: %lu", [json allKeys], (unsigned long)[json[@"imp"] count]]];
    
    // Log the complete JSON structure
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        [logger error:[NSString stringWithFormat:@"JSON serialization error: %@", error]];
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
        [logger warn:@"[ObjC-BiddingConfig] No key-value paths configuration available"];
        return;
    }
    
    BOOL shouldRemovePII = [self.privacyService shouldClearPersonalData];
    
    // Inject user key-values (respect privacy)
    if (paths.userKeyValues && !shouldRemovePII && state.userKeyValues.count > 0) {
        NSDictionary *userKV = [state.userKeyValues copy];
        [logger debug:[NSString stringWithFormat:@"Injecting %lu user key-values at path: %@", (unsigned long)userKV.count, paths.userKeyValues]];
        [json clx_putAtDynamicPath:paths.userKeyValues value:userKV];
    }
    
    // Inject app key-values (not affected by privacy)
    if (paths.appKeyValues && state.appKeyValues.count > 0) {
        NSDictionary *appKV = [state.appKeyValues copy];
        [logger debug:[NSString stringWithFormat:@"Injecting %lu app key-values at path: %@", (unsigned long)appKV.count, paths.appKeyValues]];
        [json clx_putAtDynamicPath:paths.appKeyValues value:appKV];
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
        [logger debug:[NSString stringWithFormat:@"Injecting hashed user ID at path: %@", paths.eids]];
        [json clx_putAtDynamicPath:paths.eids value:eid];
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
    // ORTB 2.5: displaymanager identifies the SDK responsible for rendering
    if (impression.displaymanager) {
        json[@"displaymanager"] = impression.displaymanager;
    }
    if (impression.displaymanagerver) {
        json[@"displaymanagerver"] = impression.displaymanagerver;
    }
    json[@"tagid"] = impression.tagid ?: @"";
    json[@"instl"] = impression.instl ?: @0;
    json[@"secure"] = @1;
    
    // ORTB 2.5: bidfloor - minimum bid price in CPM (only include if set by publisher)
    if (impression.bidfloor) {
        json[@"bidfloor"] = impression.bidfloor;
    }
    json[@"bidfloorcur"] = impression.bidfloorcur ?: @"USD";
    json[@"exp"] = impression.exp ?: @14400;
    
    // ORTB 2.5: rwdd indicates rewarded ad
    if (impression.rwdd) {
        json[@"rwdd"] = impression.rwdd;
    }
    
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
    
    [logger verbose:[NSString stringWithFormat:
        @"Session metrics: depth=%.0f, banner=%.0f, mrec=%.0f, full=%.0f, native=%.0f, rewarded=%.0f, duration=%.1fs",
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
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"format"] = [formatsArray copy];
    
    // ORTB 2.5: Ad position on screen
    if (banner.pos) {
        json[@"pos"] = banner.pos;
    }
    
    // ORTB 2.5: Top frame indicator (1 = top frame, 0 = iframe)
    if (banner.topframe) {
        json[@"topframe"] = banner.topframe;
    }
    
    return [json copy];
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
    
    // ORTB 2.5: Video duration and skip configuration
    if (video.minduration) {
        json[@"minduration"] = video.minduration;
    }
    if (video.maxduration) {
        json[@"maxduration"] = video.maxduration;
    }
    if (video.startdelay != nil) {  // Can be 0, so check for nil explicitly
        json[@"startdelay"] = video.startdelay;
    }
    if (video.skip != nil) {  // Can be 0, so check for nil explicitly
        json[@"skip"] = video.skip;
    }
    if (video.skipmin != nil) {  // Can be 0, so check for nil explicitly
        json[@"skipmin"] = video.skipmin;
    }
    if (video.skipafter) {
        json[@"skipafter"] = video.skipafter;
    }
    if (video.playbackmethod) {
        json[@"playbackmethod"] = video.playbackmethod;
    }
    
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
        [logger verbose:[NSString stringWithFormat:@"Impression ext prebid JSON: %@", json[@"prebid"]]];
    } else {
        [logger warn:@"[BiddingConfig] No prebid found in impression ext"];
    }
    if (ext.data) {
        json[@"data"] = ext.data;
    }
    // Add SKAdNetwork object for iOS attribution (IAB SKAN spec)
    if (ext.skadn) {
        json[@"skadn"] = [self convertSkadnToJSON:ext.skadn];
    }
    
    return [json copy];
}

/// Converts SKAdNetwork object to JSON per IAB SKAN specification
/// This provides bidders with attribution capability information
- (NSDictionary *)convertSkadnToJSON:(CLXBiddingConfigImpressionExtSkadn *)skadn {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // version: Highest supported SKAN version (string)
    if (skadn.version) {
        json[@"version"] = skadn.version;
    }
    
    // versions: Array of all supported SKAN versions
    if (skadn.versions && skadn.versions.count > 0) {
        json[@"versions"] = skadn.versions;
    }
    
    // sourceapp: Publisher app bundle identifier
    if (skadn.sourceapp) {
        json[@"sourceapp"] = skadn.sourceapp;
    }
    
    // skadnetids: Array of SKAdNetwork IDs from publisher's Info.plist
    if (skadn.skadnetids && skadn.skadnetids.count > 0) {
        json[@"skadnetids"] = skadn.skadnetids;
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
        [logger debug:[NSString stringWithFormat:@"Including bidder in JSON: %@", storedImpression.bidder]];
    } else {
        [logger warn:@"[BiddingConfig] No bidder configuration found in storedImpression"];
    }
    
    [logger verbose:[NSString stringWithFormat:@"Final storedImpression JSON: %@", json]];
    
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
    // ORTB 2.5: device.ua is RECOMMENDED but not REQUIRED - only include if we have a real value
    if (self.device.ua) {
        json[@"ua"] = self.device.ua;
    }
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
    
    // ORTB 2.5: lmt (Limit Ad Tracking)
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
    // Use resolution methods that fallback to legacy TCF when CMP doesn't provide GPP
    // This ensures wide DSP coverage by always sending GPP format when consent is available
    CLXConsentProvider *gppProvider = [CLXConsentProvider sharedInstance];
    
    NSString *gppString = [gppProvider resolveGppString];
    if (gppString) {
        regExt.gpp = gppString;
        
        // Per IAB spec, gpp_sid MUST be present when gpp string exists
        NSArray<NSNumber *> *gppSid = [gppProvider resolveGppSid];
        if (gppSid) {
            regExt.gppSid = gppSid;
        } else {
            // If no SID provided, use empty array (valid per IAB spec)
            [logger warn:@"[BiddingConfig] GPP string present but no SID - using empty array"];
            regExt.gppSid = @[];
        }
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
                        @"atype": uid.atype ?: @3
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
        // Per IAB spec, gpp_sid MUST be present when gpp exists (even if empty array)
        if (ext.gppSid) {
            json[@"gpp_sid"] = ext.gppSid;
        }
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

- (NSDictionary *)convertSourceToJSON {
    if (!self.source) {
        return nil;
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    // ORTB 2.5: fd indicates entity responsible for final impression sale decision
    if (self.source.fd) {
        json[@"fd"] = self.source.fd;
    }
    
    // ORTB 2.5: tid is the transaction ID for this bid request
    if (self.source.tid) {
        json[@"tid"] = self.source.tid;
    }
    
    // ORTB 2.5: pchain is the payment ID chain (ads.txt/sellers.json)
    if (self.source.pchain) {
        json[@"pchain"] = self.source.pchain;
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
@implementation CLXBiddingConfigImpressionExtSkadn
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

#pragma mark - Source
@implementation CLXBiddingConfigSource
@end

#pragma mark - Response
// All response class implementations removed - use CLXBidResponse classes instead 
